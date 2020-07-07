({
    gotoURL : function (component, event, helper) {
        let urlEvent = $A.get("e.force:navigateToURL");
        let file = component.get('v.file');
        let url = '/'+file.fileId;
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
    }
});