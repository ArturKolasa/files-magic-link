@IsTest(SeeAllData=false)
public with sharing class FilesMagicLinkControllerTest {

    @testSetup
    private static void createTestData() {
        ContentWorkspace testWorkspace = new ContentWorkspace(Name = 'TEST CLASS', DeveloperName = 'TEST_CLASS');
        insert testWorkspace;
    }

    @IsTest
    static void retrieveFilesByFoldersPositive() {
        ContentWorkspace testWorkspace = [ SELECT Id FROM ContentWorkspace WHERE Name = 'TEST CLASS' ];

        ContentFolder workspaceFolder = [ SELECT Id FROM ContentFolder WHERE Name =: testWorkspace.Id ];

        ContentFolder testFolderRecord = new ContentFolder(Name = 'TEST FOLDER', ParentContentFolderId = workspaceFolder.Id);
        insert testFolderRecord;

        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (Integer i = 1; i <= 51; i++) {
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Title'+i;
            cv.VersionData = Blob.valueOf('Test Data'+i);
            cv.PathOnClient = 'Test Path'+i+'.txt';
            contentVersions.add(cv);
        }

        insert contentVersions;

        List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
        List<ContentFolderMember> folderMembers = new List<ContentFolderMember>();

        for(ContentVersion cv : [SELECT Id, ContentDocumentId FROM ContentVersion]) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = testWorkspace.Id;
            cdl.ShareType = 'I';
            documentLinks.add(cdl);
        }

        insert documentLinks;


        for (ContentFolderMember cfm : [
                SELECT Id, ChildRecordId, ParentContentFolderId
                FROM ContentFolderMember
                WHERE ParentContentFolderId = :workspaceFolder.Id
        ]) {
            cfm.ParentContentFolderId = testFolderRecord.Id;
            folderMembers.add(cfm);
        }

        update folderMembers;

        String filesByFolders;
        Test.startTest();
        {
            filesByFolders = FilesMagicLinkController.getFilesLink('TEST CLASS/TEST FOLDER','','','','');
        }

        Test.stopTest();
        System.assertNotEquals(null,filesByFolders);
    }

    @isTest
    static void retrieveFilesByFoldersNegative(){
        String filesByFolders;
        Test.startTest();
        {
            filesByFolders = FilesMagicLinkController.getFilesLink('','','','','');
        }
        Test.stopTest();
        System.assertEquals(null,filesByFolders);
    }
}