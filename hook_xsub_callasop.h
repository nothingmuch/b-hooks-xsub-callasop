#ifndef __HOOK_XSUB_CALLASOP_H__
#define __HOOK_XSUB_CALLASOP_H__

#include "perl.h"

START_EXTERN_C

#define TRAMPOLINE(hook) PUTBACK, b_hooks_xsub_callasop_setup_trampoline(aTHX_ hook), XSRETURN(0)

#define TRAMPOLINE_HOOK(hook) OP *hook (pTHX)

typedef OP *(*b_hooks_xsub_callasop_hook_t)(pTHX);

void b_hooks_xsub_callasop_setup_trampoline (pTHX_ b_hooks_xsub_callasop_hook_t hook);

END_EXTERN_C

#endif

