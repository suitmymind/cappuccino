function objj_backtrace_format(aReceiver, aSelector)
{
    return "[<" + GETMETA(aReceiver).name + " " + (typeof sprintf == "function" ? sprintf("%#08x", aReceiver.__address) : aReceiver.__address.toString(16)) + "> " + aSelector + "]";
}

function objj_msgSend_Backtrace(/*id*/ aReceiver, /*SEL*/ aSelector)
{
    if (aReceiver == nil)
        return nil;

    objj_debug_backtrace.push(objj_backtrace_format(aReceiver, aSelector));

    try
    {
        var result = class_getMethodImplementation(aReceiver.isa, aSelector).apply(aReceiver, arguments);
    }
    catch (anException)
    {
        CPLog.error("Exception " + anException + " in " + objj_backtrace_format(aReceiver, aSelector));
        objj_debug_print_backtrace();
    }

    objj_debug_backtrace.pop();

    return result;
}

function objj_msgSendSuper_Backtrace(/*id*/ aSuper, /*SEL*/ aSelector)
{
    objj_debug_backtrace.push(objj_backtrace_format(aSuper.receiver, aSelector));
    var super_class = aSuper.super_class;

    arguments[0] = aSuper.receiver;
    
    try
    {
        var result = class_getMethodImplementation(super_class, aSelector).apply(aSuper.receiver, arguments);
    }
    catch (anException)
    {
        CPLog.error("Exception " + anException + " in " + objj_backtrace_format(aSuper.receiver, aSelector));
        objj_debug_print_backtrace();
    }

    objj_debug_backtrace.pop();

    return result;
}

function objj_msgSend_Profile(/*id*/ aReceiver, /*SEL*/ aSelector)
{
    if (aReceiver == nil)
        return nil;

    // profiling book keeping 
    var profileRecord = {
        parent      : objj_debug_profile,
        receiver    : GETMETA(aReceiver).name,
        selector    : aSelector,
        calls       : []
    }
    objj_debug_profile.calls.push(profileRecord);
    objj_debug_profile = profileRecord;
    profileRecord.start = new Date();
    
    var result = class_getMethodImplementation(aReceiver.isa, aSelector).apply(aReceiver, arguments);
    
    profileRecord.end = new Date();
    objj_debug_profile = profileRecord.parent;

    return result;
}

function objj_msgSendSuper_Profile(/*id*/ aSuper, /*SEL*/ aSelector)
{
    // profiling book keeping 
    var profileRecord = {
        parent      : objj_debug_profile,
        receiver    : GETMETA(aReceiver).name,
        selector    : aSelector,
        calls       : []
    }
    objj_debug_profile.calls.push(profileRecord);
    objj_debug_profile = profileRecord;
    profileRecord.start = new Date();

    var super_class = aSuper.super_class;

    arguments[0] = aSuper.receiver;
    
    var result = class_getMethodImplementation(super_class, aSelector).apply(aSuper.receiver, arguments);
    
    profileRecord.end = new Date();
    objj_debug_profile = profileRecord.parent;

    return result;
}

var objj_msgSend_Standard = objj_msgSend,
    objj_msgSendSuper_Standard = objj_msgSendSuper;

// FIXME: This could be much better.
var objj_debug_backtrace;
    
function objj_backtrace_set_enabled(enabled)
{
    if (enabled)
    {
        objj_debug_backtrace = [];
        objj_msgSend = objj_msgSend_Backtrace;
        objj_msgSendSuper = objj_msgSendSuper_Backtrace;
    }
    else
    {
        objj_msgSend = objj_msgSend_Standard;
        objj_msgSendSuper = objj_msgSendSuper_Standard;
    }
}

function objj_debug_print_backtrace()
{
    alert(objj_debug_backtrace_string());
}

function objj_debug_backtrace_string()
{
    return objj_debug_backtrace ? objj_debug_backtrace.join("\n") : "";
}

var objj_debug_profile = null,
    objj_currently_profiling = false,
    objj_profile_cleanup;

function objj_profile(title)
{
    if (objj_currently_profiling)
        return;
    
    var objj_msgSend_profile_saved = objj_msgSend,
        objj_msgSendSuper_profile_saved = objj_msgSendSuper;
    
    objj_msgSend = objj_msgSend_Profile;
    objj_msgSendSuper = objj_msgSendSuper_Profile;
    
    var root = { calls: [] };
    objj_debug_profile = root;
    
    var context = {
        start : new Date(),
        title : title,
        profile : root
    };

    objj_profile_cleanup = function() {
        objj_msgSend = objj_msgSend_profile_saved;
        objj_msgSendSuper = objj_msgSendSuper_profile_saved;
        context.end = new Date();
        return context;
    }
    
    objj_currently_profiling = true;
}

function objj_profileEnd()
{
    if (!objj_currently_profiling)
        return;
    
    objj_debug_profile = null;
    objj_currently_profiling = false;
    
    return objj_profile_cleanup();
}
