//' $Header:   P:/PVCS/MAX/INCLUDE/IOFMT.PRV   1.0   25 Sep 1996 10:40:22   BOB  $
// Header file for IOFMT.C

#ifdef __cplusplus
extern "C" {
#endif

int _cdecl     sscanf	  (const char	  *source, const char *fmt, ...);
int _cdecl FAR sscanf_far (const char FAR *source, const char *fmt, ...);

#ifdef __cplusplus
}
#endif

