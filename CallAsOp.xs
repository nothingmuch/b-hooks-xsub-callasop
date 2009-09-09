#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "hook_xsub_callasop.h"


#define MY_CXT_KEY "B::Hooks::XSUB::CallAsOp::_guts" XS_VERSION

typedef struct {
	OP fakeop;
	UNOP trampoline;

	/* the actual function to call as if it were pp_addr */

	TRAMPOLINE_HOOK((*hook));
} my_cxt_t;

START_MY_CXT

static void setup_trampoline_cb (pTHX_ void *ptr) {
	dMY_CXT;
	int flags = GIMME_V;

	assert(MY_CXT.hook);

	Zero(&MY_CXT.trampoline, 1, UNOP);

	/* this is modeled after call_sv and friends
	 *
	 * we recreate MY_CXT.trampoline to be an entersub-like opcode, fired at
	 * the same stack depth etc as the entersub that invoked the XSUB
	 *
	 * the difference is that the op_ppaddr points at the hook that was saved
	 * by the TRAMPOLINE macro */
	if (!(flags & G_NOARGS))
		MY_CXT.trampoline.op_flags |= OPf_STACKED;

	MY_CXT.trampoline.op_flags |= ((flags & G_VOID) ? OPf_WANT_VOID :
		(flags & G_ARRAY) ? OPf_WANT_LIST : OPf_WANT_SCALAR);

	MY_CXT.trampoline.op_type = OP_ENTERSUB;    /* we pretend it's an entersub, it's called in the same context */
	MY_CXT.trampoline.op_next = PL_op->op_next; /* to return from this op we go to what entersub should have returned to */
	MY_CXT.trampoline.op_ppaddr = MY_CXT.hook;  /* the body of the op is the user's hook */

	MY_CXT.hook = NULL;

	/* ENTERSUB will return PL_op->op_next causing execution of the trampoline, fakeop is there only for its op_next */
	MY_CXT.fakeop.op_next = (OP *)&MY_CXT.trampoline;
	PL_op = &MY_CXT.fakeop;

	assert(PL_op->op_next);
	assert(PL_op->op_next->op_next);
}

void b_hooks_xsub_callasop_setup_trampoline (pTHX_ b_hooks_xsub_callasop_hook_t hook) {
	dMY_CXT;


	assert(MY_CXT.hook == NULL);

	/* save the hook somewhere */
	MY_CXT.hook = hook;

	/* SAVEDESTRUCTOR_X will fire inside LEAVE in the ENTERSUB for XSUBs */
	SAVEDESTRUCTOR_X(setup_trampoline_cb, NULL);


	SAVESTACK_POS(); /* Enforce some insanity in scalar context... we want to
						let the our fake op hook manipulate the stack and it's
						their responsibility to respect GIMME_V. this disposes
						of the extra null SV injected in scalar context when no
						value was left on the stack */
}



static TRAMPOLINE_HOOK(test)
{
	dSP;
	dMARK;

	PUSHMARK(SP);

	mXPUSHs(newSVpvs("trampoline"));
	mXPUSHs(newSVpvs("Test::More::pass"));

	PUTBACK;

	return PL_ppaddr[OP_ENTERSUB](aTHX);
}

MODULE = B::Hooks::XSUB::CallAsOp	PACKAGE = B::Hooks::XSUB::CallAsOp

BOOT:
{
	MY_CXT_INIT;
	MY_CXT.hook = NULL;
}

void __test ()
	PPCODE:
		TRAMPOLINE(test);

