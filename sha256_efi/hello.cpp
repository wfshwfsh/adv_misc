#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <iostream>
#include <string>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <openssl/evp.h>

using namespace std;

#define EFI_VARIABLE_GUID "12345678-abcd-ef01-2345-6789abcdef01"
#define VAR_NAME "MyCustomVar"
#define EFIVARS_PATH "/sys/firmware/efi/efivars/"
#define EFI_VARIABLE_ATTRIBUTES 0x00000007 

// 與 Shell 腳本完全對齊的金鑰與 IV
const unsigned char key[] = "0123456789abcdef0123456789abcdef"; // 32 bytes
const unsigned char iv[]  = "abcdef0123456789";                 // 16 bytes

/**
 * @brief 使用 AES-256-CBC 加密輸入字串
 * @param plaintext       要加密的源字串
 * @param ciphertext_len  [輸出參數] 用來傳回加密後的實際密文長度
 * @return uint8_t* 指向動態分配密文緩衝區的指標，失敗回傳 NULL (呼叫者需手動 free)
 */
static uint8_t* encrypt_AES256(const string& plaintext, int* ciphertext_len)
{
    *ciphertext_len = 0;
    
    EVP_CIPHER_CTX *ctx = EVP_CIPHER_CTX_new();
    if (!ctx) {
        cerr << "EVP_CIPHER_CTX_new Fail" << endl;
        return NULL;
    }

    if (EVP_EncryptInit_ex(ctx, EVP_aes_256_cbc(), NULL, key, iv) != 1) {
        cerr << "AES init failed" << endl;
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }

    size_t max_len = plaintext.length() + 16;
    uint8_t *ciphertext = static_cast<uint8_t*>(malloc(max_len));
    if (!ciphertext) {
        perror("Malloc ciphertext failed");
        EVP_CIPHER_CTX_free(ctx);
        return NULL;
    }

    int len = 0;
    int total_len = 0;

    if (EVP_EncryptUpdate(ctx, ciphertext, &len, (const unsigned char*)plaintext.c_str(), plaintext.length()) != 1) {
        cerr << "AES encrypt failed (Update)" << endl;
        EVP_CIPHER_CTX_free(ctx);
        free(ciphertext);
        return NULL;
    }
    total_len = len;

    if (EVP_EncryptFinal_ex(ctx, ciphertext + len, &len) != 1) {
        cerr << "AES encrypt failed (Final)" << NULL;
        EVP_CIPHER_CTX_free(ctx);
        free(ciphertext);
        return NULL;
    }
    total_len += len;
    EVP_CIPHER_CTX_free(ctx);

    *ciphertext_len = total_len;
    return ciphertext;
}

/**
 * @brief 將二進位密文加上 UEFI 屬性標頭，並寫入指定之 efivars 節點
 * @param filepath       完整的 efivars 檔案路徑
 * @param attributes     UEFI 變數屬性遮罩 (例如 0x07)
 * @param payload        加密後的二進位密文指標
 * @param payload_len    密文長度
 * @return bool 成功回傳 true，失敗回傳 false
 */
static bool write_EFI_variable(const char* filepath, uint32_t attributes, const uint8_t* payload, size_t payload_len)
{
    // 配置總寫入緩衝區 (4位元組屬性標頭 + 實際密文長度)
    size_t total_len = sizeof(uint32_t) + payload_len;
    uint8_t *buffer = static_cast<uint8_t*>(malloc(total_len));
    if (!buffer) {
        perror("Malloc write buffer failed");
        return false;
    }

    // 1. 填入前 4 個位元組的 UEFI 屬性
    memcpy(buffer, &attributes, sizeof(attributes));

    // 2. 填入密文資料
    memcpy(buffer + sizeof(attributes), payload, payload_len);

    // 3. 確保徹底抹除舊變數節點，避免舊資料干擾
    unlink(filepath);

    // 4. 以二進位安全模式 ("wb") 寫入 efivars 檔案系統
    FILE *fp = fopen(filepath, "wb");
    if (!fp) {
        perror("Open efivars file failed");
        free(buffer);
        return false;
    }
    
    size_t written = fwrite(buffer, 1, total_len, fp);
    fclose(fp);
    free(buffer);

    // 檢查寫入長度是否完全符合預期
    if (written < total_len) {
        cerr << "Write to efivars completed partially or failed." << endl;
        return false;
    }

    return true;
}

int main() {
    // 建立完整的 efivars 檔案路徑
    char filepath[512]={};
    snprintf(filepath, sizeof(filepath), "%s%s-%s", EFIVARS_PATH, VAR_NAME, EFI_VARIABLE_GUID);

    string my_plaintext = "Hello UEFI NVRAM! 12345";
    int ciphertext_len = 0;

    // 1. 呼叫加密功能
    uint8_t *encrypted_data = encrypt_AES256(my_plaintext, &ciphertext_len);
    if (!encrypted_data) {
        cerr << "加密程序出錯，終止執行。" << endl;
        return EXIT_FAILURE;
    }

    // 2. 呼叫寫入功能
    bool success = write_EFI_variable(filepath, EFI_VARIABLE_ATTRIBUTES, encrypted_data, ciphertext_len);
    
    // 寫入完成後，不論成功與否，立刻釋放加密暫存記憶體
    free(encrypted_data); 

    if (!success) {
        cerr << "寫入 EFI 節點失敗。" << endl;
        return EXIT_FAILURE;
    }

    printf("Successfully created UEFI node: %s\n", filepath);
    printf("Plaintext length: %zu, Ciphertext length: %d\n", my_plaintext.length(), ciphertext_len);
    printf("Total wrote %zu bytes (4 bytes attributes + %d bytes encrypted data)\n", 
            sizeof(uint32_t) + ciphertext_len, ciphertext_len);

    return EXIT_SUCCESS;
}