#ifdef DEBUG
#define ENABLE_LOGS
#endif

#ifdef ENABLE_LOGS
void JBLogDebug(const char *format, ...);
void JBLogError(const char *format, ...);
#else
#define JBLogDebug(format ...)
#define JBLogError(format ...)
#endif

//#define JBLogDebug(format ...) NSLog(@format)
//#define JBLogError(format ...) NSLog(@format)
