({
    redirectToNewRecord: function() {
        var navService = window.location;
        navService.assign("/lightning/o/Case/list?filterName=Recent");
    }
})