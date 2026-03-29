List<FlowDefinitionView> defs = [
    SELECT Id, ApiName, ActiveVersionId, LatestVersionId, IsActive
    FROM FlowDefinitionView
    WHERE ApiName = 'VerificationCodeLoginFlow'
    LIMIT 1
];
if (!defs.isEmpty()) {
    FlowDefinitionView d = defs[0];
    System.debug('IsActive=' + d.IsActive + 
                 ' ActiveVer=' + d.ActiveVersionId + 
                 ' LatestVer=' + d.LatestVersionId +
                 ' Same=' + (d.ActiveVersionId == d.LatestVersionId));
}
