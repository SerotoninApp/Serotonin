#import <Foundation/Foundation.h>
int spawnRoot(NSString* path, NSArray* args, NSString** stdOut, NSString** stdErr);
//extern void killall(NSString* processName);

//extern LSApplicationProxy* findPersistenceHelperApp(PERSISTENCE_HELPER_TYPE allowedTypes);

//typedef struct __SecCode const *SecStaticCodeRef;
//
//typedef CF_OPTIONS(uint32_t, SecCSFlags) {
//    kSecCSDefaultFlags = 0
//};
//#define kSecCSRequirementInformation 1 << 2
//#define kSecCSSigningInformation 1 << 1
//
//OSStatus SecStaticCodeCreateWithPathAndAttributes(CFURLRef path, SecCSFlags flags, CFDictionaryRef attributes, SecStaticCodeRef *staticCode);
//OSStatus SecCodeCopySigningInformation(SecStaticCodeRef code, SecCSFlags flags, CFDictionaryRef *information);
//CFDataRef SecCertificateCopyExtensionValue(SecCertificateRef certificate, CFTypeRef extensionOID, bool *isCritical);
//void SecPolicySetOptionsValue(SecPolicyRef policy, CFStringRef key, CFTypeRef value);
//
//extern CFStringRef kSecCodeInfoEntitlementsDict;
//extern CFStringRef kSecCodeInfoCertificates;
//extern CFStringRef kSecPolicyAppleiPhoneApplicationSigning;
//extern CFStringRef kSecPolicyAppleiPhoneProfileApplicationSigning;
//extern CFStringRef kSecPolicyLeafMarkerOid;
//
//extern SecStaticCodeRef getStaticCodeRef(NSString *binaryPath);
//extern NSDictionary* dumpEntitlements(SecStaticCodeRef codeRef);
//extern NSDictionary* dumpEntitlementsFromBinaryAtPath(NSString *binaryPath);
//extern NSDictionary* dumpEntitlementsFromBinaryData(NSData* binaryData);
