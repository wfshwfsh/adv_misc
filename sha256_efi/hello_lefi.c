#include <stdio.h>
#include <stdlib.h>
#include <efivar/efivar.h>

#define VAR_NAME "MyCustomVar"

efi_guid_t my_guid;

int main() {
    // 使用標準的 EFI Global Variable GUID
    // 這裡使用 libefivar 自帶的 efi_guid_global
    //efi_guid_t guid = efi_guid_global;
    
    sscanf("12345678-abcd-ef01-2345-6789abcdef01", 
       "%x-%hx-%hx-%hx-%2hhx%2hhx%2hhx%2hhx%2hhx%2hhx",
       &my_guid.a, 
       &my_guid.b, 
       &my_guid.c, 
       &my_guid.d,
       &my_guid.e[0], &my_guid.e[1], &my_guid.e[2], 
       &my_guid.e[3], &my_guid.e[4], &my_guid.e[5]);
    

    const char *data = "Hello UEFI NVRAM! 888888888888888888";
    size_t data_size = strlen(data);

    // 設置 UEFI 變數屬性
    // EFI_VARIABLE_NON_VOLATILE | EFI_VARIABLE_BOOTSERVICE_ACCESS | EFI_VARIABLE_RUNTIME_ACCESS
    uint32_t attributes = 0x00000007;

    // 先嘗試刪除舊變數（UEFI 規範中，長度為 0 且屬性合法的 SetVariable 代表刪除）
    efi_del_variable(my_guid, VAR_NAME);

    // 使用核心標準函式庫寫入變數
    int ret = efi_set_variable(my_guid, VAR_NAME, (uint8_t *)data, data_size, attributes, 0644);
    
    if (ret < 0) {
        perror("efi_set_variable failed");
        return EXIT_FAILURE;
    }

    printf("Successfully created UEFI node using libefivar!\n");
    return EXIT_SUCCESS;
}
