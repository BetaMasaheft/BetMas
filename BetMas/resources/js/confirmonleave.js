$(window).on("beforeunload",function(event) {
    return "You have some unsaved changes";
});