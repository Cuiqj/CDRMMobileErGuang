//
//  AtonementNoticePrintViewController.m
//  GDRMMobile
//
//  Created by yu hongwu on 12-11-29.
//
//

#import "AtonementNoticePrintViewController.h"
#import "AtonementNotice.h"
#import "CaseDeformation.h"
#import "CaseProveInfo.h"
#import "Citizen.h"
#import "CaseInfo.h"
#import "RoadSegment.h"
#import "OrgInfo.h"
#import "UserInfo.h"
#import "NSNumber+NumberConvert.h"
#import "Systype.h"
#import "MatchLaw.h"
#import "MatchLawDetails.h"
#import "LawItems.h"
#import "LawbreakingAction.h"
#import "Laws.h"
#import "FileCode.h"

#import "DateSelectController.h"

static NSString * xmlName = @"AtonementNoticeTable";

@interface AtonementNoticePrintViewController ()
@property (nonatomic,retain) AtonementNotice *notice;

- (void)generateDefaultsForNotice:(AtonementNotice *)notice;
@end

@implementation AtonementNoticePrintViewController
@synthesize labelCaseCode = _labelCaseCode;
@synthesize textParty = _textParty;
@synthesize textPartyAddress = _textPartyAddress;
@synthesize textCaseReason = _textCaseReason;
@synthesize textOrg = _textOrg;
@synthesize textViewCaseDesc = _textViewCaseDesc;
@synthesize textWitness = _textWitness;
@synthesize textViewPayReason = _textViewPayReason;
@synthesize textPayMode = _textPayMode;
@synthesize textCheckOrg = _textCheckOrg;
@synthesize labelDateSend = _labelDateSend;
@synthesize textBankName = _textBankName;
@synthesize caseID = _caseID;
@synthesize notice = _notice;

- (void)viewDidLoad
{
    [super setCaseID:self.caseID];
    NSString * strtemp = [[AppDelegate App] serverAddress];
    
//    if ([strtemp isEqualToString:@"http://219.131.172.163:81/irmsdatagy/"]) {
//        xmlName = @"GYAtonementNoticeTable";
//    }
    [self LoadPaperSettings:xmlName];
    /*modify by lxm 不能实时更新*/
     if (![self.caseID isEmpty]) {
         NSArray *noticeArray = [AtonementNotice AtonementNoticesForCase:self.caseID];
         if (noticeArray.count>0) {
             self.notice = [noticeArray objectAtIndex:0];
         } else {
             self.notice = [AtonementNotice newDataObjectWithEntityName:@"AtonementNotice"];
         }
         if (!self.notice.caseinfo_id || [self.notice.caseinfo_id isEmpty]) {
             self.notice.caseinfo_id = self.caseID;
             [self generateDefaultsForNotice:self.notice];
         }
        [self loadPageInfo];
     }
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setLabelCaseCode:nil];
    [self setTextParty:nil];
    [self setTextPartyAddress:nil];
    [self setTextCaseReason:nil];
    [self setTextOrg:nil];
    [self setTextViewCaseDesc:nil];
    [self setTextWitness:nil];
    [self setTextViewPayReason:nil];
    [self setTextPayMode:nil];
    [self setTextCheckOrg:nil];
    [self setLabelDateSend:nil];
    [self setNotice:nil];
	[self setTextBankName:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)pageSaveInfo
{
    [self savePageInfo];
}

- (void)loadPageInfo{
    CaseInfo *caseInfo = [CaseInfo caseInfoForID:self.caseID];
    self.labelCaseCode.text = [[NSString alloc] initWithFormat:@"(%@)年%@交赔字第%@号",caseInfo.case_mark2, [FileCode fileCodeWithPredicateFormat:@"赔补偿案件编号"].organization_code, caseInfo.full_case_mark3];
    Citizen *citizen = [Citizen citizenForCitizenName:self.notice.citizen_name nexus:@"当事人" case:self.caseID];
    CaseProveInfo *proveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
    self.textParty.text = citizen.party;
    self.textPartyAddress.text = citizen.address;
    self.textCaseReason.text = [NSString stringWithFormat:@"%@%@因%@%@", citizen.automobile_number, citizen.automobile_pattern, caseInfo.case_reason,proveInfo.case_short_desc];
    self.textOrg.text = self.notice.organization_id;
    self.textViewCaseDesc.text = self.notice.case_desc;
    
    //案件勘验详情
    self.textWitness.text = self.notice.witness;
    self.textViewPayReason.text = self.notice.pay_reason;
    
    NSArray *temp=[Citizen allCitizenNameForCase:self.caseID];
    NSArray *citizenList=[[temp valueForKey:@"automobile_number"] mutableCopy];
    
    NSArray *deformations = [CaseDeformation deformationsForCase:self.caseID forCitizen:[citizenList objectAtIndex:0]];
    double summary=[[deformations valueForKeyPath:@"@sum.total_price.doubleValue"] doubleValue];
    NSNumber *sumNum = @(summary);
    NSString *numString = [sumNum numberConvertToChineseCapitalNumberString];
    self.textPayMode.text = [NSString stringWithFormat:@"路产损失费人民币%@（￥%.2f元）",numString,summary];
    
    self.textBankName.text = [[Systype typeValueForCodeName:@"交款地点"] objectAtIndex:0];
    self.textCheckOrg.text = self.notice.check_organization;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"yyyy     年      MM      月      dd      日"];
//    self.labelDateSend.text = [dateFormatter stringFromDate:self.notice.date_send];
    self.TextDateSend.text = [dateFormatter stringFromDate:self.notice.date_send];
    [self.labelDateSend setHidden:YES];
    
}

- (void)generateDefaultAndLoad
{
    [self generateDefaultsForNotice:self.notice];
    [self loadPageInfo];
}

- (void)savePageInfo{
    CaseProveInfo *proveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
    proveInfo.case_long_desc = self.textCaseReason.text;
    self.notice.organization_id = self.textOrg.text;
    self.notice.case_desc = self.textViewCaseDesc.text;
    self.notice.pay_mode = self.textPayMode.text;
    self.notice.pay_reason = self.textViewPayReason.text;
    self.notice.check_organization = self.textCheckOrg.text;
    self.notice.witness = self.textWitness.text;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"yyyy     年      MM      月      dd      日"];
    self.notice.date_send = [dateFormatter dateFromString:self.TextDateSend.text];
    [[AppDelegate App] saveContext];
}

- (void)generateDefaultsForNotice:(AtonementNotice *)notice{
    CaseProveInfo *proveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
    proveInfo.event_desc = [CaseProveInfo generateEventDescForCase:self.caseID];

    NSDateFormatter *codeFormatter = [[NSDateFormatter alloc] init];
    [codeFormatter setDateFormat:@"yyyyMM'0'dd"];
    [codeFormatter setLocale:[NSLocale currentLocale]];
    notice.code = [codeFormatter stringFromDate:[NSDate date]];
    NSRange range = [proveInfo.event_desc rangeOfString:@"于"];
    notice.case_desc = [proveInfo.event_desc substringFromIndex:range.location+1];
    if ([self isTextBeyondRect:notice.case_desc] == TRUE) {
        NSRange startRange = [proveInfo.event_desc rangeOfString:@"于"];
        NSRange endRange = [proveInfo.event_desc rangeOfString:@"损坏路产如下："];
        NSRange range;
        
        if (startRange.location != NSNotFound) {
            range = NSMakeRange(startRange.location, [proveInfo.event_desc length] - startRange.location);
        }
        
        if (endRange.location != NSNotFound) {
            range.length = endRange.location - startRange.location + 7;
        }
        
        notice.case_desc = [proveInfo.event_desc substringWithRange:range];
        notice.case_desc = [NSString stringWithFormat:@"%@%@",notice.case_desc,@"详细见《公路赔（补）偿清单》"];

    }
    notice.citizen_name = proveInfo.citizen_name;
    notice.witness = @"现场照片、勘验检查笔录、询问笔录、现场勘验图";
    NSString *currentUserID=[[NSUserDefaults standardUserDefaults] stringForKey:USERKEY];
    notice.organization_id = [[OrgInfo orgInfoForOrgID:[UserInfo userInfoForUserID:currentUserID].organization_id] valueForKey:@"orgname"];
    notice.check_organization = [[Systype typeValueForCodeName:@"复核单位"] objectAtIndex:0];
//    NSMutableArray *matchLaws = [NSMutableArray array];
//    NSArray *lawbreakingActionArr = [LawbreakingAction LawbreakingActionsForCase:proveInfo.case_desc_id];
//    if (lawbreakingActionArr) {
//        for (LawbreakingAction *lawbreakAction in lawbreakingActionArr) {
//            NSArray *matchLawArr = [MatchLaw matchLawsForLawbreakingActionID:lawbreakAction.myid];
//            if (matchLawArr) {
//                for (MatchLaw *matchLaw in matchLawArr) {
//                    NSArray *matchLawDetailsArr = [MatchLawDetails matchLawDetailsForMatchlawID:matchLaw.myid];
//                    if (matchLawDetailsArr) {
//                        for (MatchLawDetails *matchLawDetails in matchLawDetailsArr) {
//                            Laws *laws = [Laws lawsForLawID:matchLawDetails.law_id];
//                            LawItems *lawItems = [LawItems lawItemForLawID:matchLawDetails.law_id andItemNo:matchLawDetails.lawitem_id];
//                            if (lawItems.lawitem_no) {
//                                [matchLaws addObject:[NSString stringWithFormat:@"《%@》第%@条", laws.caption, lawItems.lawitem_no]];
//                            }else{
//                                [matchLaws addObject:[NSString stringWithFormat:@"《%@》", laws.caption]];
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
    
    Citizen *citizen = [Citizen citizenForCitizenName:notice.citizen_name nexus:@"当事人" case:self.caseID];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"MatchLaw" ofType:@"plist"];
    NSDictionary *matchLaws = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *payReason = @"";
    if (matchLaws) {
        NSString *breakStr = @"";
        NSString *matchStr = @"";
        NSString *payStr = @"";
        NSDictionary *matchInfo = [[matchLaws objectForKey:@"case_desc_match_law"] objectForKey:proveInfo.case_desc_id];
        if (matchInfo) {
            if ([matchInfo objectForKey:@"breakLaw"]) {
                breakStr = [(NSArray *)[matchInfo objectForKey:@"breakLaw"] componentsJoinedByString:@"、"];
            }
            if ([matchInfo objectForKey:@"matchLaw"]) {
                matchStr = [(NSArray *)[matchInfo objectForKey:@"matchLaw"] componentsJoinedByString:@"、"];
            }
            if ([matchInfo objectForKey:@"payLaw"]) {
                payStr = [(NSArray *)[matchInfo objectForKey:@"payLaw"] componentsJoinedByString:@"、"];
            }
        }

        //payReason = [NSString stringWithFormat:@"%@%@的违法事实清楚，其行为违反了%@规定，根据%@、并依照%@的规定，当事人应当承担民事责任，赔偿路产损失。", citizen.party, proveInfo.case_short_desc, breakStr, matchStr, payStr];
        payReason = [NSString stringWithFormat:@"%@规定，根据%@、并依照%@",  breakStr, matchStr, payStr];
        
    }
    notice.pay_reason = payReason;
    NSArray *deformations = [CaseDeformation deformationsForCase:self.caseID forCitizen:notice.citizen_name];
    double summary=[[deformations valueForKeyPath:@"@sum.total_price.doubleValue"] doubleValue];
    NSNumber *sumNum = @(summary);
    NSString *numString = [sumNum numberConvertToChineseCapitalNumberString];
    notice.pay_mode = [NSString stringWithFormat:@"路产损失费人民币%@（￥%.2f元）",numString,summary];
    notice.date_send = [NSDate date];
    [[AppDelegate App] saveContext];
}

/*test by lxm 无效*/
-(NSURL *)toFullPDFWithTable:(NSString *)filePath{
    [self savePageInfo];
    if (![filePath isEmpty]) {
        CGRect pdfRect=CGRectMake(0.0, 0.0, paperWidth, paperHeight);
        UIGraphicsBeginPDFContextToFile(filePath, CGRectZero, nil);
        UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
        [self drawStaticTable:xmlName];
        [self drawDateTable:xmlName withDataModel:self.notice];
        
        //add by lxm 2013.05.08
        CaseInfo *caseInfo = [CaseInfo caseInfoForID:self.caseID];
        self.labelCaseCode.text = [[NSString alloc] initWithFormat:@"(%@)年%@高交赔字第%@号",caseInfo.case_mark2, [[AppDelegate App].projectDictionary objectForKey:@"cityname"], caseInfo.full_case_mark3];
        Citizen *citizen = [Citizen citizenForCitizenName:self.notice.citizen_name nexus:@"当事人" case:self.caseID];
        [self drawDateTable:xmlName withDataModel:citizen];
         [self drawDateTable:xmlName withDataModel:caseInfo];
        CaseProveInfo *proveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
        [self drawDateTable:xmlName withDataModel:proveInfo];
        
        
        UIGraphicsEndPDFContext();
        return [NSURL fileURLWithPath:filePath];
    } else {
        return nil;
    }
}

-(NSURL *)toFullPDFWithPath:(NSString *)filePath{
    //套打
    [self savePageInfo];
    if (![filePath isEmpty]) {
        CGRect pdfRect=CGRectMake(0.0, 0.0, paperWidth, paperHeight);
        UIGraphicsBeginPDFContextToFile(filePath, CGRectZero, nil);
        UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
        [self drawStaticTable1:xmlName];
        [self drawDateTable:xmlName withDataModel:self.notice];
        
        //add by lxm 2013.05.08
        CaseInfo *caseInfo = [CaseInfo caseInfoForID:self.caseID];
        [self drawDateTable:xmlName withDataModel:caseInfo];
        [self drawDateTable:xmlName withDataModel:caseInfo];
        
        Citizen *citizen = [Citizen citizenForCitizenName:self.notice.citizen_name nexus:@"当事人" case:self.caseID];
        [self drawDateTable:xmlName withDataModel:citizen];
        
        CaseProveInfo *proveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
        [self drawDateTable:xmlName withDataModel:proveInfo];
        
        UIGraphicsEndPDFContext();
        return [NSURL fileURLWithPath:filePath];
    } else {
        return nil;
    }
}

-(NSURL *)toFormedPDFWithPath:(NSString *)filePath{
    [self savePageInfo];
    if (![filePath isEmpty]) {
        CGRect pdfRect=CGRectMake(0.0, 0.0, paperWidth, paperHeight);
        NSString *formatFilePath = [NSString stringWithFormat:@"%@.format.pdf", filePath];
        UIGraphicsBeginPDFContextToFile(formatFilePath, CGRectZero, nil);
        UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
        [self drawDateTable:xmlName withDataModel:self.notice];
        
        //add by lxm 2013.05.08
        CaseInfo *caseInfo = [CaseInfo caseInfoForID:self.caseID];
        [self drawDateTable:xmlName withDataModel:caseInfo];
        
        Citizen *citizen = [Citizen citizenForCitizenName:self.notice.citizen_name nexus:@"当事人" case:self.caseID];
        [self drawDateTable:xmlName withDataModel:citizen];
        
        CaseProveInfo *proveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
        [self drawDateTable:xmlName withDataModel:proveInfo];
        
        UIGraphicsEndPDFContext();
        return [NSURL fileURLWithPath:formatFilePath];
    } else {
        return nil;
    }
}
//打印数据，仿宋
- (BOOL)isTextBeyondRect:(NSString *)content{

        NSString *xmlString = [self xmlStringFromFile:xmlName];
        TBXML *tbxml = [TBXML newTBXMLWithXMLString:xmlString error:nil];
        TBXMLElement *root = tbxml.rootXMLElement;
        if (!root) {
            return FALSE;
        }
        TBXMLElement *dataTable = [TBXML childElementNamed:@"DataTable" parentElement:root];
        if (!dataTable) {
            return FALSE;
        }
        TBXMLElement *renderUnitElement = dataTable->firstChild;
        while (renderUnitElement) {
            TBXMLElement *contentElement = [TBXML childElementNamed:@"content" parentElement:renderUnitElement];
            if (contentElement) {
                    TBXMLElement *dataElement = [TBXML childElementNamed:@"data" parentElement:contentElement];
                    if (dataElement) {
                            TBXMLElement *attributeNameElement = [TBXML childElementNamed:@"attributeName" parentElement:dataElement];
                            if (attributeNameElement) {
                                NSString *elementValue = [TBXML textForElement:attributeNameElement];
                                if ([elementValue isEqualToString:@"case_desc"]) {
                                    if ([[TBXML elementName:renderUnitElement] isEqualToString:@"UITextView"]){
                                        CGFloat fontSize = 12;
                                        TBXMLElement *originInXML=[TBXML childElementNamed:@"origin" parentElement:renderUnitElement];
                                        if (originInXML) {
                                            CGFloat x=[[TBXML valueOfAttributeNamed:@"x" forElement:originInXML] floatValue]*MMTOPIX * SCALEFACTOR;
                                            CGFloat y=[[TBXML valueOfAttributeNamed:@"y" forElement:originInXML] floatValue]*MMTOPIX * SCALEFACTOR;
                                            
                                            TBXMLElement *fontSizeInXML=[TBXML childElementNamed:@"fontSize" parentElement:renderUnitElement];
                                            if (fontSizeInXML) {
                                                fontSize=[[TBXML textForElement:fontSizeInXML] floatValue];
                                            }
                                            UITextAlignment alignment = UITextAlignmentLeft;
                                            TBXMLElement *alignmentInXML = [TBXML childElementNamed:@"alignment" parentElement:renderUnitElement];
                                            if (alignmentInXML) {
                                                NSString *alignmentString = [TBXML textForElement:alignmentInXML];
                                                alignmentString = [alignmentString lowercaseString];
                                                if (![alignmentString isEmpty]) {
                                                    if ([alignmentString isEqualToString:@"center"]) {
                                                        alignment = UITextAlignmentCenter;
                                                    } else if ([alignmentString isEqualToString:@"right"]){
                                                        alignment = UITextAlignmentRight;
                                                    }
                                                }
                                            }
                                            CGFloat leftOffset = 0;
                                            TBXMLElement *leftOffsetInXML = [TBXML childElementNamed:@"leftOffSet" parentElement:renderUnitElement];
                                            if (leftOffsetInXML) {
                                                leftOffset = [TBXML textForElement:leftOffsetInXML].floatValue*MMTOPIX * SCALEFACTOR;
                                            }
                                            //默认无行高,直接画出
                                            CGFloat lineHeight = 0;
                                            TBXMLElement *lineHeightInXML = [TBXML childElementNamed:@"lineHeight" parentElement:renderUnitElement];
                                            if (lineHeightInXML) {
                                                lineHeight = [TBXML textForElement:lineHeightInXML].floatValue;
                                            }
                                            TBXMLElement *sizeInXML = [TBXML childElementNamed:@"size" parentElement:renderUnitElement];
                                            if (sizeInXML) {
                                                CGFloat width = [TBXML valueOfAttributeNamed:@"width" forElement:sizeInXML].floatValue*MMTOPIX * SCALEFACTOR;
                                                CGFloat height = [TBXML valueOfAttributeNamed:@"height" forElement:sizeInXML].floatValue*MMTOPIX * SCALEFACTOR;
                                                
                                                CGRect rect = CGRectMake(x, y, width, height);
                                                UIFont *font = [UIFont fontWithName:SongTi size:fontSize];
                                                return [content isTextBeyondRect:rect withFont:font horizontalAlignment:alignment leftOffSet:leftOffset lineHeight:lineHeight];
                                            }
                                        }
                                    }
                                }
                            }
                    }
            }
            renderUnitElement = renderUnitElement->nextSibling;
        }
    return FALSE;
}


- (IBAction)textDownClick:(id)sender {
    UIStoryboard *MainStoryboard            = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    DateSelectController *datePicker = [MainStoryboard instantiateViewControllerWithIdentifier:@"datePicker"];
    datePicker.delegate=self;
    datePicker.pickerType=0;
    // [datePicker showdate:self.textDate.text];
    UITextField* textField = (UITextField* )sender;
    CGRect frame = textField.frame;
    self.pickerPopover=[[UIPopoverController alloc] initWithContentViewController:datePicker];
    [self.pickerPopover presentPopoverFromRect:frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionRight animated:YES];
    datePicker.dateselectPopover=self.pickerPopover;
}
- (void)setDate:(NSString *)date{
    NSDateFormatter * formator =[[NSDateFormatter alloc]init];
    [formator setLocale:[NSLocale currentLocale]];
    [formator setDateFormat:@"yyyy-MM-dd"];
    self.notice.date_send = [formator dateFromString:date];
    [formator setDateFormat:@"yyyy     年      MM      月      dd      日"];
    self.TextDateSend.text = [formator stringFromDate:self.notice.date_send];
}
@end
