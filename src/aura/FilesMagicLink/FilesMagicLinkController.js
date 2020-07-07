({
    doInit : function(component, event, helper) {
        helper.turnOnSpinner(component);
        let action = component.get("c.getFilesLink");
        action.setParams({
            "folderPath1": component.get('v.folderPath1'),
            "folderPath2": component.get('v.folderPath2'),
            "folderPath3": component.get('v.folderPath3'),
            "folderPath4": component.get('v.folderPath4'),
            "folderPath5": component.get('v.folderPath5')
        });
        action.setCallback(this,function(response) {
            let state = response.getState();
            if(state === "SUCCESS") {
                helper.turnOffSpinner(component);
                let resWrapper = JSON.parse(response.getReturnValue());
                if(resWrapper !== null && resWrapper !== undefined){
                    component.set('v.filesByFolder',resWrapper);
                    component.set('v.firstFolderName',resWrapper[0].folderName);
                } else {
                    component.set('v.noFoldersWithFiles',true);
                }
            } else if(state === "ERROR") {
                helper.turnOffSpinner(component);
                console.error('error');
            }
        });
        $A.enqueueAction(action);
    }
});