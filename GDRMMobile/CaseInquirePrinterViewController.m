//
//  CaseInquirePrinterViewController.m
//  GDRMMobile
//
//  Created by yu hongwu on 12-8-9.
//  Copyright (c) 2012年 中交宇科 . All rights reserved.
//

#import "CaseInquirePrinterViewController.h"
#import "UserInfo.h"
#import "Citizen.h"
#import "CaseInfo.h"
#import "CaseProveInfo.h"

static NSString * const xmlName = @"InquireTable";
static NSString * const lastPageXmlName = @"last_page_InquireTable"; //该文件改用来作为第二页 | xushiwen | 2013.7.30
static NSString * const secondPageXmlName = @"second_page_InquireTable"; //该文件改用来作为第二页 | xushiwen | 2013.7.30
static NSString * const firstPageXmlName = @"first_page_InquireTable"; //该文件改用来作为第二页 | xushiwen | 2013.7.30

static NSString *textID1;
static NSString *textID2;

enum kPageInfo {
    kPageInfoFirstPage = 0,
    kPageInfoSucessivePage,
    kPageInfoLastPage,
    kPageInfoOnlyPage
};

@interface CaseInquirePrinterViewController ()
@property (nonatomic, retain) CaseInquire *caseInquire;
@end

@implementation CaseInquirePrinterViewController
@synthesize caseID=_caseID;

- (void)viewDidLoad
{
    [super setCaseID:self.caseID];
    [self LoadPaperSettings:xmlName];
    CGRect viewFrame = CGRectMake(0.0, 0.0, VIEW_FRAME_WIDTH, VIEW_FRAME_HEIGHT);
    self.view.frame = viewFrame;
    if (![self.caseID isEmpty]) {
        
    }
    if (![self.caseID isEmpty]) {
        self.caseInquire = [CaseInquire inquireForCase:self.caseID];
        if (self.caseInquire) {
            [self pageLoadInfo];
        }
    }
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)pageSaveInfo{
    Citizen *citizen = [Citizen citizenForCitizenName:self.caseInquire.answerer_name nexus:self.caseInquire.relation case:self.caseID];
    citizen.tel_number = self.textphone.text;
    self.caseInquire.phone = self.textphone.text;
    self.textaddress.text = self.caseInquire.address;

    citizen.postalcode = self.textpostalcode.text;
    self.caseInquire.postalcode = self.textpostalcode.text;
    self.caseInquire.inquiry_note = self.textinquiry_note.text;
    [[AppDelegate App] saveContext];
}


- (void)pageLoadInfo{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    [dateFormatter setDateFormat:@"yyyy年MM月dd日HH时mm分"];
    self.textdate_inquired.text =[dateFormatter stringFromDate:self.caseInquire.date_inquired];
    self.textlocality.text = self.caseInquire.locality;
    self.textinquirer_name.text = self.caseInquire.inquirer_name;
    self.textrecorder_name.text = self.caseInquire.recorder_name;
    self.textanswerer_name.text = self.caseInquire.answerer_name;
    self.textsex.text = self.caseInquire.sex;
    self.textage.text = (self.caseInquire.age.integerValue==0)?@"":[NSString stringWithFormat:@"%d",self.caseInquire.age.integerValue];
    self.textrelation.text = self.caseInquire.relation;
    
    Citizen *citizen = [Citizen citizenForCitizenName:self.caseInquire.answerer_name nexus:self.caseInquire.relation case:self.caseID];
    if ([self.caseInquire.company_duty isEmpty]) {
        self.caseInquire.company_duty = [NSString stringWithFormat:@"%@%@", citizen.org_name, citizen.profession];
    }
    self.textcompany_duty.text = self.caseInquire.company_duty;
    if ([self.caseInquire.phone isEmpty]) {
        self.caseInquire.phone = citizen.tel_number;
    }
    self.textphone.text = self.caseInquire.phone;
    self.textaddress.text = self.caseInquire.address;
    if ([self.caseInquire.postalcode isEmpty]) {
        self.caseInquire.postalcode = citizen.postalcode;
    }
    self.textpostalcode.text = self.caseInquire.postalcode;
    self.textinquiry_note.text = self.caseInquire.inquiry_note;
    [[AppDelegate App] saveContext];
}

-(NSURL *)toFormedPDFWithPath:(NSString *)filePath{
    //增加
    NSString *currentUserID = [[NSUserDefaults standardUserDefaults] stringForKey:USERKEY];
    UserInfo *userInfo = [UserInfo userInfoForUserID:currentUserID];
    // [self drawDateTable:lastPageXmlName withDataModel:userInfo];
    
    
    if (!self.caseInquire) {
        return nil;
    }
    [self pageSaveInfo];
    if (![filePath isEmpty]) {
        NSString *formatFilePath = [NSString stringWithFormat:@"%@.format.pdf", filePath];
        CGRect pdfRect = CGRectMake(0.0, 0.0, paperWidth, paperHeight);
        UIGraphicsBeginPDFContextToFile(formatFilePath, CGRectZero, nil);
        NSArray *pages = [self pagesSplitted];
        NSMutableDictionary *dataInfo = [self getDataInfo];
        
        
        if ([pages count] < 2) {
            //增加dataInfo的键值
            dataInfo[@"PageNumberInfo"][@"textID1"][@"value"] = textID1;
            dataInfo[@"PageNumberInfo"][@"textID2"][@"value"] = textID2;
            
            dataInfo[@"PageNumberInfo"][@"pageCount"][@"value"] = @([pages count]);
            dataInfo[@"PageNumberInfo"][@"pageNumber"][@"value"] = @([pages count]);
            
            UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
            [self drawDataTable:xmlName withDataInfo:dataInfo];
            
        } else {
            
            for (NSInteger i = 0 ; i < pages.count; i++) {
                //增加dataInfo的键值
                dataInfo[@"PageNumberInfo"][@"textID1"][@"value"] = textID1;
                dataInfo[@"PageNumberInfo"][@"textID2"][@"value"] = textID2;
                //第i页
                dataInfo[@"CaseInquire"][@"inquiry_note"][@"value"] = pages[i];     //也会影响到dataInfo[@"Default"]对应的值
                dataInfo[@"PageNumberInfo"][@"pageCount"][@"value"] = @([pages count]);
                dataInfo[@"PageNumberInfo"][@"pageNumber"][@"value"] = @(i + 1);
                
                UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
                if (i == 0) {
                    [self drawDataTable:firstPageXmlName withDataInfo:dataInfo];
                } else if (i == pages.count - 1){
                    [self drawDataTable:lastPageXmlName withDataInfo:dataInfo];
                } else{
                    [self drawDataTable:secondPageXmlName withDataInfo:dataInfo];
                }
            }
        }
        UIGraphicsEndPDFContext();
        return [NSURL fileURLWithPath:formatFilePath];
    } else {
        return nil;
    }
}

-(NSURL *)toFullPDFWithPath:(NSString *)filePath{
    
    //这是取当前等录入的
    //UserInfo * userinfo =[UserInfo userInfoForUserID:[[NSUserDefaults standardUserDefaults] objectForKey:USERKEY]];
    //这是取记录里的
    UserInfo *userinfo = [UserInfo userInfoForUserName:self.caseInquire.inquirer_name];
    textID1 = userinfo.exelawid;
    NSLog(@"执法编号执法编号执法标号%@",textID1);
    NSArray *inspectorArray = [[NSUserDefaults standardUserDefaults] objectForKey:INSPECTORARRAYKEY];
    NSArray *data=[UserInfo allUserInfo];
    for (UserInfo *user in data) {
        NSString *userName = [user valueForKey:@"username"];
        NSString *userID = [user valueForKey:@"myid"];
        if ([userName isEqualToString:[inspectorArray firstObject]]) {
            
            // self.textPromoterName2.text = name;
            //取当前登录人的
            //textID2 =[UserInfo userInfoForUserID:userID].exelawid;
            //取当前记录里的
            textID2 =[UserInfo userInfoForUserName:self.caseInquire.recorder_name].exelawid;
            NSLog(@"执法编号执法编号执法标号%@",textID2);
        }
    }

//    NSLog(@"执法编号执法编号执法标号%@",[inspectorArray firstObject]);
//    NSLog(@"%02d",2);
    
    //[self drawDateTable:xmlName withDataModel:];
//    CaseProveInfo* caseProveInfo = [CaseProveInfo proveInfoForCase:self.caseID];
//    [self drawDateTable:xmlName withDataModel:caseProveInfo];
    
    
    if (!self.caseInquire) {
        return nil;
    }
    [self pageSaveInfo];
    if (![filePath isEmpty]) {
        CGRect pdfRect=CGRectMake(0.0, 0.0, paperWidth, paperHeight);
        UIGraphicsBeginPDFContextToFile(filePath, CGRectZero, nil);
        NSArray *pages = [self pagesSplitted];
        NSMutableDictionary *dataInfo = [self getDataInfo];
        
        if ([pages count] < 2) {
            //增加dataInfo的键值
            dataInfo[@"PageNumberInfo"][@"textID1"][@"value"] = textID1;
            dataInfo[@"PageNumberInfo"][@"textID2"][@"value"] = textID2;
            
            dataInfo[@"PageNumberInfo"][@"pageCount"][@"value"] = @([pages count]);
            dataInfo[@"PageNumberInfo"][@"pageNumber"][@"value"] = @([pages count]);
            
            UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
            [self drawStaticTable:xmlName];
            [self drawDataTable:xmlName withDataInfo:dataInfo];
        } else {
            
            for (NSInteger i = 0 ; i < pages.count; i++) {
                //增加dataInfo的键值
                dataInfo[@"PageNumberInfo"][@"textID1"][@"value"] = textID1;
                dataInfo[@"PageNumberInfo"][@"textID2"][@"value"] = textID2;
                
                //第i页
                dataInfo[@"CaseInquire"][@"inquiry_note"][@"value"] = pages[i];     //也会影响到dataInfo[@"Default"]对应的值
                dataInfo[@"PageNumberInfo"][@"pageCount"][@"value"] = @([pages count]);
                dataInfo[@"PageNumberInfo"][@"pageNumber"][@"value"] = @(i + 1);
                
                
                UIGraphicsBeginPDFPageWithInfo(pdfRect, nil);
                
                if (i == 0) {
                    [self drawStaticTable:firstPageXmlName];
                    [self drawDataTable:firstPageXmlName withDataInfo:dataInfo];
                } else if (i == pages.count - 1){
                    [self drawStaticTable:lastPageXmlName];
                    [self drawDataTable:lastPageXmlName withDataInfo:dataInfo];
                } else{
                    [self drawStaticTable:secondPageXmlName];
                    [self drawDataTable:secondPageXmlName withDataInfo:dataInfo];
                }
            }
        }
        UIGraphicsEndPDFContext();
        return [NSURL fileURLWithPath:filePath];
    } else {
        return nil;
    }
}


- (NSArray *)pagesSplitted {
    NSString *inquiryNote = self.caseInquire.inquiry_note;
    
    CGFloat fontSize1 = [self fontSizeInPage:kPageInfoFirstPage];
    CGFloat lineHeight1 = [self lineHeightInPage:kPageInfoFirstPage];
    UIFont *font1 = [UIFont fontWithName:SongTi size:fontSize1];
    CGRect page1Rect = [self rectInPage:kPageInfoFirstPage];
    
    CGFloat fontSize2 = [self fontSizeInPage:kPageInfoSucessivePage];
    CGFloat lineHeight2 = [self lineHeightInPage:kPageInfoSucessivePage];
    UIFont *font2 = [UIFont fontWithName:SongTi size:fontSize2];
    CGRect page2Rect = [self rectInPage:kPageInfoSucessivePage];
    
    
    CGFloat fontSize3 = [self fontSizeInPage:kPageInfoLastPage];
    CGFloat lineHeight3 = [self lineHeightInPage:kPageInfoLastPage];
    UIFont *font3 = [UIFont fontWithName:SongTi size:fontSize3];
    CGRect page3Rect = [self rectInPage:kPageInfoLastPage];
    
    
    CGFloat fontSize4 = [self fontSizeInPage:kPageInfoOnlyPage];
    CGFloat lineHeight4 = [self lineHeightInPage:kPageInfoOnlyPage];
    UIFont *font4 = [UIFont fontWithName:SongTi size:fontSize4];
    CGRect page4Rect = [self rectInPage:kPageInfoOnlyPage];
    
    NSArray *pages = [inquiryNote pagesWithFont:font4 lineHeight:lineHeight4 horizontalAlignment:UITextAlignmentLeft page1Rect:page4Rect followPageRect:page4Rect];
    NSLog(@"%d",[pages count]);
    if ([pages count] >= 2) {
        pages = [inquiryNote pagesWithFont:font1 lineHeight:lineHeight1 horizontalAlignment:UITextAlignmentLeft page1Rect:page1Rect followPageRect:page1Rect];
        NSMutableArray *tempArr = [[NSMutableArray alloc] init];
        if ([pages count] >= 2) {
            NSString *textInFirstPage = pages[kPageInfoFirstPage];
            NSRange firstpageRange = NSMakeRange(0, [textInFirstPage length]);
            NSString *textInSuccessivePage = [inquiryNote stringByReplacingCharactersInRange:firstpageRange withString:@""];
            NSArray *successivePages = [textInSuccessivePage pagesWithFont:font2 lineHeight:lineHeight2 horizontalAlignment:UITextAlignmentLeft page1Rect:page2Rect followPageRect:page2Rect];
            NSInteger length = 0;
            for (NSInteger i = 0; i < successivePages.count-1; i++) {
                length += [successivePages[i] length];
            }
            NSRange lastpageRange = NSMakeRange(0, length);
            NSString *lastInSuccessivePage = [textInSuccessivePage stringByReplacingCharactersInRange:lastpageRange withString:@""];
            NSArray *lastPages = [lastInSuccessivePage pagesWithFont:font3 lineHeight:lineHeight3 horizontalAlignment:UITextAlignmentLeft page1Rect:page3Rect followPageRect:page3Rect];
            
            if ([lastPages count] >= 2 ) {
                [tempArr addObject:pages[kPageInfoFirstPage]];
                [tempArr addObjectsFromArray:successivePages];
                [tempArr addObject:@""];
                NSLog(@"test%@test",tempArr[tempArr.count -2]);
            }else {
                [tempArr addObject:pages[kPageInfoFirstPage]];
                [tempArr addObjectsFromArray:successivePages];
                [tempArr addObjectsFromArray:lastPages];
                [tempArr removeObjectAtIndex:successivePages.count];

            }

        }else {
            
            [tempArr addObject:pages[kPageInfoFirstPage]];
            [tempArr addObject:@""];
            
        }
        pages = [tempArr copy];
    }
    return pages;
}


- (CGFloat)fontSizeInPage:(NSInteger)pageNo {
    NSString *xmlPathString = nil;
    
    if (pageNo == kPageInfoFirstPage) {
        xmlPathString = [super xmlStringFromFile:firstPageXmlName];
    } else if (pageNo == kPageInfoSucessivePage) {
        xmlPathString = [super xmlStringFromFile:secondPageXmlName];
    }else if (pageNo == kPageInfoLastPage) {
        xmlPathString = [super xmlStringFromFile:lastPageXmlName];
    }else if (pageNo == kPageInfoOnlyPage) {
        xmlPathString = [super xmlStringFromFile:xmlName];
    }
    NSError *err;
    TBXML *xmlTree = [TBXML newTBXMLWithXMLString:xmlPathString error:&err];
    NSAssert(err==nil, @"Fail when creating TBXML object: %@", err.description);
    
    TBXMLElement *root = xmlTree.rootXMLElement;
    NSArray *elementsWrapped = [TBXML findElementsFrom:root byDotSeparatedPath:@"DataTable.UITextView" withPredicate:@"content.data.attributeName = inquiry_note"];
    NSAssert([elementsWrapped count]>0, @"Element not found.");
    
    NSValue *elementWrapped = elementsWrapped[0];
    TBXMLElement *inqurynoteElement = elementWrapped.pointerValue;

    TBXMLElement *fontSizeElement = [TBXML childElementNamed:@"fontSize" parentElement:inqurynoteElement error:&err];
    NSAssert(err==nil, @"Fail when looking up child element: %@", err.description);
    
    return [[TBXML textForElement:fontSizeElement] floatValue];
}

- (CGFloat)lineHeightInPage:(NSInteger)pageNo {
    NSString *xmlPathString = nil;
    
    if (pageNo == kPageInfoFirstPage) {
        xmlPathString = [super xmlStringFromFile:firstPageXmlName];
    } else if (pageNo == kPageInfoSucessivePage) {
        xmlPathString = [super xmlStringFromFile:secondPageXmlName];
    }else if (pageNo == kPageInfoLastPage) {
        xmlPathString = [super xmlStringFromFile:lastPageXmlName];
    }else if (pageNo == kPageInfoOnlyPage) {
        xmlPathString = [super xmlStringFromFile:xmlName];
    }
    
    NSError *err;
    TBXML *xmlTree = [TBXML newTBXMLWithXMLString:xmlPathString error:&err];
    NSAssert(err==nil, @"Fail when creating TBXML object: %@", err.description);
    
    TBXMLElement *root = xmlTree.rootXMLElement;
    NSArray *elementsWrapped = [TBXML findElementsFrom:root byDotSeparatedPath:@"DataTable.UITextView" withPredicate:@"content.data.attributeName = inquiry_note"];
    NSAssert([elementsWrapped count]>0, @"Element not found.");
    
    NSValue *elementWrapped = elementsWrapped[0];
    TBXMLElement *inqurynoteElement = elementWrapped.pointerValue;
    
    TBXMLElement *lineHeightElement = [TBXML childElementNamed:@"lineHeight" parentElement:inqurynoteElement error:&err];
    NSAssert(err==nil, @"Fail when looking up child element: %@", err.description);
    
    return [[TBXML textForElement:lineHeightElement] floatValue];
}

- (CGRect)rectInPage:(NSInteger)pageNo {
    NSString *xmlPathString = nil;
    
    if (pageNo == kPageInfoFirstPage) {
        xmlPathString = [super xmlStringFromFile:firstPageXmlName];
    } else if (pageNo == kPageInfoSucessivePage) {
        xmlPathString = [super xmlStringFromFile:secondPageXmlName];
    }else if (pageNo == kPageInfoLastPage) {
        xmlPathString = [super xmlStringFromFile:lastPageXmlName];
    }else if (pageNo == kPageInfoOnlyPage) {
        xmlPathString = [super xmlStringFromFile:xmlName];
    }
    NSError *err;
    TBXML *xmlTree = [TBXML newTBXMLWithXMLString:xmlPathString error:&err];
    NSAssert(err==nil, @"Fail when creating TBXML object: %@", err.description);
    
    TBXMLElement *root = xmlTree.rootXMLElement;
    NSArray *elementsWrapped = [TBXML findElementsFrom:root byDotSeparatedPath:@"DataTable.UITextView" withPredicate:@"content.data.attributeName = inquiry_note"];
    NSAssert([elementsWrapped count]>0, @"Element not found.");
    
    NSValue *elementWrapped = elementsWrapped[0];
    TBXMLElement *inqurynoteElement = elementWrapped.pointerValue;
    
    TBXMLElement *sizeElement = [TBXML childElementNamed:@"size" parentElement:inqurynoteElement error:&err];
    NSAssert(err==nil, @"Fail when looking up child element: %@", err.description);
    
    TBXMLElement *originElement = [TBXML childElementNamed:@"origin" parentElement:inqurynoteElement error:&err];
    NSAssert(err==nil, @"Fail when looking up child element: %@", err.description);
    
    NSAssert(sizeElement != nil && originElement != nil, @"Fail when looking up child element 'size' or 'origin'");
    
    CGFloat x = [[TBXML valueOfAttributeNamed:@"x" forElement:originElement] floatValue] * MMTOPIX * SCALEFACTOR;
    CGFloat y = [[TBXML valueOfAttributeNamed:@"y" forElement:originElement] floatValue] * MMTOPIX * SCALEFACTOR;
    CGFloat width = [[TBXML valueOfAttributeNamed:@"width" forElement:sizeElement] floatValue] * MMTOPIX * SCALEFACTOR;
    CGFloat height = [[TBXML valueOfAttributeNamed:@"height" forElement:sizeElement] floatValue] * MMTOPIX * SCALEFACTOR;
    return CGRectMake(x, y, width, height);
}


- (NSMutableDictionary *)getDataInfo{
    // dataInfo用法:
    // (1) id value = dataInfo[实体名][属性名][@"value"]
    // (2) NSAttributeDescription *desc = dataInfo[实体名][属性名][@"valueType"]
    // (3) dataInfo[@"Default"]针对XML中未指名实体的项
    NSMutableDictionary *dataInfo = [[NSMutableDictionary alloc] init];
    
    //将CaseInquire的属性名、属性值、属性描述装入dataInfo
    NSMutableDictionary *caseInquireDataInfo = [[NSMutableDictionary alloc] init];
    NSDictionary *caseInquireAttributes = [self.caseInquire.entity attributesByName];
    for (NSString *attribName in caseInquireAttributes.allKeys) {
        id attribValue = [self.caseInquire valueForKey:attribName];
        NSAttributeDescription *attribDesc = [caseInquireAttributes objectForKey:attribName];
        NSAttributeType attribType = attribDesc.attributeType;
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              attribValue,@"value",
                              @(attribType),@"valueType",nil];
        [caseInquireDataInfo setObject:data forKey:attribName];

    }
    
    //修改 将UserInfo的属性名、属性值、属性描述装入dataInfo
    NSString *currentUserID = [[NSUserDefaults standardUserDefaults] stringForKey:USERKEY];
    UserInfo *userInfo = [UserInfo userInfoForUserID:currentUserID];
    NSMutableDictionary *caseInfouserInfo = [[NSMutableDictionary alloc] init];
    NSDictionary *caseInfouserAttributes = [userInfo.entity attributesByName];
    for (NSString *attribName in caseInfouserAttributes.allKeys) {
        id attribValue = [userInfo valueForKey:attribName];
        NSAttributeDescription *attribDesc = [caseInfouserAttributes objectForKey:attribName];
        NSAttributeType attribType = attribDesc.attributeType;
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     attribValue,@"value",
                                     @(attribType),@"valueType",nil];
        [caseInfouserInfo setObject:data forKey:attribName];
    }

    
    //将CaseInfo的属性名、属性值、属性描述装入dataInfo
    CaseInfo *relativeCaseInfo = [CaseInfo caseInfoForID:self.caseID];
    NSMutableDictionary *caseInfoDataInfo = [[NSMutableDictionary alloc] init];
    NSDictionary *caseInfoAttributes = [relativeCaseInfo.entity attributesByName];
    for (NSString *attribName in caseInfoAttributes.allKeys) {
        id attribValue = [relativeCaseInfo valueForKey:attribName];
        NSAttributeDescription *attribDesc = [caseInfoAttributes objectForKey:attribName];
        NSAttributeType attribType = attribDesc.attributeType;
        NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              attribValue,@"value",
                              @(attribType),@"valueType",nil];
        [caseInfoDataInfo setObject:data forKey:attribName];
    }
    
    //设置一个Default（针对xml里没有entityName的节点），指向caseInquireDataInfo
    [dataInfo setObject:caseInquireDataInfo forKey:@"Default"];
    [dataInfo setObject:caseInquireDataInfo forKey:[self.caseInquire.entity name]];
    
    [dataInfo setObject:caseInfoDataInfo forKey:[relativeCaseInfo.entity name]];
    //修改
    // [dataInfo setObject:@"测试" forKey:@"textID1"];
    
    //预留页码位置
    NSMutableDictionary *pageCountInfo = [[NSMutableDictionary alloc] init];
    [pageCountInfo setObject:@(NSInteger32AttributeType) forKey:@"valueType"];
    
    NSMutableDictionary *pageNumberInfo = [[NSMutableDictionary alloc] init];
    [pageNumberInfo setObject:@(NSInteger32AttributeType) forKey:@"valueType"];
    
    //修改
    NSMutableDictionary *textIdInfo = [[NSMutableDictionary alloc] init];
    [textIdInfo setObject:@(NSStringAttributeType) forKey:@"valueType"];
    
    NSMutableDictionary *textIdInfo2 = [[NSMutableDictionary alloc] init];
    [textIdInfo2 setObject:@(NSStringAttributeType) forKey:@"valueType"];
    
    [dataInfo setObject:[@{@"pageCount":pageCountInfo, @"pageNumber":pageNumberInfo,@"textID1":textIdInfo,@"textID2":textIdInfo2} mutableCopy]
                 forKey:@"PageNumberInfo"];
    
    return dataInfo;
}

@end
