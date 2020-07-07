public with sharing class FilesMagicLinkController {

    class FolderWrapper {
        public String folderName;
        public List<FileWrapper> fileWrappers;
    }

    class FileWrapper {
        public String fileTitle;
        public String fileId;
    }

    @AuraEnabled
    public static String getFilesLink(String folderPath1, String folderPath2, String folderPath3,
            String folderPath4, String folderPath5) {

        Map<String, List<String>> libraryName2folderName = new Map<String, List<String>>();
        Map<String, List<String>> parentFolderName2folderName = new Map<String, List<String>>();

        gatherFolderInformation(folderPath1, folderPath2, folderPath3, folderPath4, folderPath5,
                libraryName2folderName, parentFolderName2folderName);

        if(libraryName2folderName.isEmpty() && parentFolderName2folderName.isEmpty()){ return null;}

        List<Id> folderIds = new List<Id>();
        List<String> parentFolderNames = new List<String>();
        retrieveContentWorkspaceIds(libraryName2folderName, folderIds, parentFolderNames);
        List<String> folderNames = new List<String>();
        populateFolderNames(parentFolderName2folderName, folderNames, libraryName2folderName);
        populateParentFolderNames(parentFolderNames, parentFolderName2folderName);
        populateFolderIds(folderNames, parentFolderNames, folderIds);

        if(folderIds.isEmpty()){ return null;}

        return JSON.serialize(createFolderWrappers(folderIds));
    }

    private static void populateParentFolderNames(List<String> parentFolderNames, Map<String, List<String>> parentFolderName2folderName) {
        parentFolderNames.addAll(parentFolderName2folderName.keySet());
    }

    private static void populateFolderIds(List<String> folderNames, List<String> parentFolderNames, List<Id> folderIds) {
        for (ContentFolder contentFolder : [
                SELECT Id, Name
                FROM ContentFolder
                WHERE Name IN :folderNames
                AND ParentContentFolder.Name IN :parentFolderNames
        ]) {
            folderIds.add(contentFolder.Id);
        }
    }

    private static void populateFolderNames(Map<String, List<String>> parentFolderName2folderName, List<String> folderNames, Map<String, List<String>> libraryName2folderName) {
        for (List<String> folderName : parentFolderName2folderName.values()) {
            folderNames.addAll(folderName);
        }
        for (List<String> folderName : libraryName2folderName.values()) {
            folderNames.addAll(folderName);
        }
    }

    private static void retrieveContentWorkspaceIds(Map<String, List<String>> libraryName2folderName, List<Id> folderIds, List<String> parentFolderNames) {
        for (ContentWorkspace cw : [SELECT Id FROM ContentWorkspace WHERE Name IN :libraryName2folderName.keySet()]) {
            folderIds.add(cw.Id);
            parentFolderNames.add(cw.Id);
        }
    }

    private static List<FolderWrapper> createFolderWrappers(List<Id> folderIds) {
        List<FolderWrapper> folderWrappers = new List<FolderWrapper>();
        Map<String, List<AggregateResult>> folderName2aggregateResult = new Map<String, List<AggregateResult>>();
        for (AggregateResult ar : [
                SELECT ParentContentFolder.Name, Title,FileExtension, FileType, Id
                FROM ContentFolderItem
                WHERE ParentContentFolderId IN :folderIds
                GROUP BY ParentContentFolder.Name, Title, FileExtension, FileType, Id
        ]) {
            if (ar.get('FileType') == null) { continue;}

            String folderName = ar.get('Name').toString();
            if (folderName2aggregateResult.containsKey(folderName)) {
                folderName2aggregateResult.get(folderName).add(ar);
            } else {
                folderName2aggregateResult.put(folderName, new List<AggregateResult>{
                        ar
                });
            }
        }

        for (String folderName : folderName2aggregateResult.keySet()) {
            Integer counter = 0;
            FolderWrapper folderWrapper = new FolderWrapper();
            folderWrapper.folderName = folderName;
            List<FileWrapper> fileWrappers = new List<FileWrapper>();
            for (AggregateResult ar : folderName2aggregateResult.get(folderName)) {
                if(counter == 50){
                    break;
                }
                counter++;
                FileWrapper fileWrapper = new FileWrapper();
                String fileTitle = ar.get('Title').toString().replaceAll('_', ' ');
                fileTitle += ar.get('FileExtension') != null ? '.' + ar.get('FileExtension').toString() : '';
                fileWrapper.fileTitle = fileTitle;
                fileWrapper.fileId = ar.get('Id').toString();
                fileWrappers.add(fileWrapper);
            }
            folderWrapper.fileWrappers = fileWrappers;
            folderWrappers.add(folderWrapper);
        }
        return folderWrappers;
    }

    private static void gatherFolderInformation(String folderPath1, String folderPath2, String folderPath3,
            String folderPath4, String folderPath5, Map<String, List<String>> libraryName2folderName,
            Map<String, List<String>> parentFolderName2folderName)
    {
        retrieveFolderInformation(folderPath1, libraryName2folderName, parentFolderName2folderName);
        retrieveFolderInformation(folderPath2, libraryName2folderName, parentFolderName2folderName);
        retrieveFolderInformation(folderPath3, libraryName2folderName, parentFolderName2folderName);
        retrieveFolderInformation(folderPath4, libraryName2folderName, parentFolderName2folderName);
        retrieveFolderInformation(folderPath5, libraryName2folderName, parentFolderName2folderName);
    }

    private static List<Id> retrieveFolderInformation(String folderPath1, Map<String, List<String>> libraryName2folderName,
            Map<String, List<String>> parentFolderName2folderName) {

        if(String.isBlank(folderPath1)){
            return new List<Id>();
        }
        List<Id> folderIds = new List<Id>();
        Integer folderSum = folderPath1.countMatches('/');
        String folderName = folderPath1.substringAfterLast('/');
        if (folderSum == 1) {
            String libraryName = folderPath1.substringBefore('/');
            if(libraryName2folderName.containsKey(libraryName)){
                libraryName2folderName.get(libraryName).add(folderName);
            } else {
                libraryName2folderName.put(libraryName,new List<String>{folderName});
            }
        } else {
            String parentFolder = folderPath1.remove('/' + folderPath1.substringAfterLast('/')).substringAfterLast('/');
            if(parentFolderName2folderName.containsKey(parentFolder)){
                parentFolderName2folderName.get(parentFolder).add(folderName);
            } else {
                parentFolderName2folderName.put(parentFolder,new List<String>{folderName});
            }
        }

        return folderIds;
    }

}