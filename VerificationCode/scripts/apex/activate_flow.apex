List<FlowDefinitionView> flows = [
    SELECT Id, ApiName, ActiveVersionId, LatestVersionId, IsActive
    FROM FlowDefinitionView
    WHERE ApiName = 'VerificationCodeLoginFlow'
    LIMIT 1
];
if (!flows.isEmpty()) {
    System.debug('Flow: ' + flows[0].ApiName + 
                 ' IsActive: ' + flows[0].IsActive +
                 ' ActiveVersion: ' + flows[0].ActiveVersionId +
                 ' LatestVersion: ' + flows[0].LatestVersionId);
} else {
    System.debug('Flow NOT found');
}
