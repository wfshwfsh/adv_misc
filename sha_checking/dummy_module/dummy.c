#include <linux/module.h>
#include <linux/init.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/kernel.h>
#include <crypto/hash.h>
#include <linux/efi.h>
#include <linux/version.h>
#include <crypto/hash.h>
#include <crypto/sha2.h>
#include <linux/slab.h>
#include <linux/ctype.h>


#define SHA256_LEN 32
#define SHA_FILE_PATH "/sys/firmware/efi/efivars/BIOSString-aaaa0056-3341-44b5-9c9c-6d76f76738bb"
#define DEFAULT_EFI_BIOSSTR_PATH	"BIOSString-aaaa0056-3341-44b5-9c9c-6d76f76738bb"
#define DEFAULT_EFIVAR_FS_PATH		"/sys/firmware/efi/efivars/"



efi_status_t read_efi_variable(efi_char16_t *name,
                               efi_guid_t *guid,
                               u8 **out_buf,
                               unsigned long *out_size,
                               u32 *out_attr)
{
    unsigned long size = 0;
    u32 attr = 0;
    void *buf;
    efi_status_t status;

    if (!efi_enabled(EFI_RUNTIME_SERVICES) || !efi.get_variable)
        return EFI_UNSUPPORTED;

    /* first call to get size */
    status = efi.get_variable(name, guid, &attr, &size, NULL);
    if (!(status == EFI_BUFFER_TOO_SMALL || size > 0))
        return status;

    buf = kmalloc(size, GFP_KERNEL);
    if (!buf)
        return EFI_OUT_OF_RESOURCES;

    status = efi.get_variable(name, guid, &attr, &size, buf);
    if (EFI_IS_ERROR(status)) {
        kfree(buf);
        return status;
    }

    *out_buf  = buf;
    *out_size = size;
    if (out_attr)
        *out_attr = attr;

    return EFI_SUCCESS;
}

static bool is_printable_ascii(u8 c)
{
    return (c >= 0x20 && c <= 0x7e);
}

static char *extract_before_bios(const u8 *buf, size_t size)
{
    size_t i;
    char *out;

    for (i = 0; i + 4 < size; i++) {
        /* 避免掃到 binary */
        if (!is_printable_ascii(buf[i]))
            break;

        /* 找到 "BIOS" */
        if (buf[i] == 'B' &&
            buf[i + 1] == 'I' &&
            buf[i + 2] == 'O' &&
            buf[i + 3] == 'S')
            break;
    }

    out = kmalloc(i + 1, GFP_KERNEL);
    if (!out)
        return NULL;

    memcpy(out, buf, i);
    out[i] = '\0';
    return out;
}

static bool is_platform_char(char c)
{
    return (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') ||
           (c == '-');
}

static char *extract_platform_id(const char *in)
{
    const char *p = in;
    const char *start;
    size_t len, total;
    char *out;

    /* 跳過非平台字元 */
    while (*p && !is_platform_char(*p))
        p++;

    start = p;

    /* 收集平台字元 */
    while (*p && is_platform_char(*p))
        p++;

    len = p - start;
    total = len + 3 /*append 3 char*/;
    if (len == 0)
        return NULL;

    out = kmalloc(len + 1, GFP_KERNEL);
    if (!out)
        return NULL;

    memcpy(out, start, len);
    
    out[len + 0] = out[len-1]; /* last */
    out[len + 1] = out[0]; /* first */
    out[len + 2] = out[2]; /* third */

    out[total] = '\0';
    return out;
}

int calc_sha256(const char *data, size_t len, unsigned char *hash)
{
    struct crypto_shash *tfm;
    struct shash_desc *shash;
    int ret;

    tfm = crypto_alloc_shash("sha256", 0, 0);
    if (IS_ERR(tfm))
        return PTR_ERR(tfm);

    shash = kmalloc(sizeof(*shash) + crypto_shash_descsize(tfm), GFP_KERNEL);
    if (!shash) {
        crypto_free_shash(tfm);
        return -ENOMEM;
    }

    shash->tfm = tfm;
    //shash->flags = 0;
    ret = crypto_shash_init(shash);
    if (ret)
        goto out;

    ret = crypto_shash_update(shash, data, len);
    if (ret)
        goto out;

    ret = crypto_shash_final(shash, hash);

    print_hex_dump(KERN_INFO, "sha256: ",
               DUMP_PREFIX_NONE,
               16, 1,
               hash, SHA256_DIGEST_SIZE,
               false);
    
out:
    kfree(shash);
    crypto_free_shash(tfm);
    return ret;
}

static void sha256_to_upper_hex(const u8 *hash, char *out)
{
    int i;
    bin2hex(out, hash, SHA256_DIGEST_SIZE);
    
    for (i = 0; i < SHA256_DIGEST_SIZE * 2; i++)
        out[i] = toupper(out[i]);
    
    out[SHA256_DIGEST_SIZE * 2] = '\0';
}

static int __init dummy_init(void)
{
    int ret;
    u8 *data;
    unsigned long size;
    u32 attr;
    efi_status_t status;
    char *str=NULL, *platformId=NULL;
    unsigned char hash[SHA256_LEN]={};
    unsigned char hash_str[SHA256_LEN*2+1]={};
    efi_guid_t guid = EFI_GUID(0xaaaa0056,0x3341,0x44b5,
                           0x9c,0x9c,0x6d,0x76,
                           0xf7,0x67,0x38,0xbb);

    pr_info("dummy module loaded\n");

    status = read_efi_variable(L"BIOSString", &guid, &data, &size, &attr);
    if (status == EFI_SUCCESS) {
	kfree(data);
    } else {
        pr_err("read_efi_variable failed\n");
        return status;
    }
    
    print_hex_dump(KERN_INFO, "efi_data: ",
               DUMP_PREFIX_OFFSET,
               16, 1,
               data, size,
               true);
    
    str = extract_before_bios(data, size);
    if (str) {
        pr_info("EFI string: \"%s\"\n", str);

        platformId = extract_platform_id(str);
	pr_info("platformId: \"%s\"\n", platformId);
	kfree(str);

        ret = calc_sha256(platformId, strlen(platformId), hash);
	sha256_to_upper_hex(hash, hash_str);
	pr_info("hash_str: \"%s\"\n", hash_str);
	kfree(platformId);
        if (ret) {
            pr_err("calc_sha256 failed\n");
            return ret;
	}
    }

    return 0;
}

static void __exit dummy_exit(void)
{
    pr_info("dummy module unloaded\n");
}

module_init(dummy_init);
module_exit(dummy_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Will");
MODULE_DESCRIPTION("Dummy kernel module");
