//
//  ViewController.m
//  p103
//
//  Created by SDT-1 on 2014. 1. 13..
//  Copyright (c) 2014년 SDT-1. All rights reserved.
//

#import "ViewController.h"
#import <sqlite3.h>
#import "movie.h"
@interface ViewController ()
@property (weak,nonatomic)IBOutlet UITableView *table;

@end

@implementation ViewController{
    NSMutableArray *data;
    sqlite3 *db;
}
-(void)openDB{
    NSString *docPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *dbFilePath = [docPath stringByAppendingPathComponent:@"fd.sqlite"];
    NSFileManager*fm = [NSFileManager defaultManager];
    bool existFile = [fm fileExistsAtPath:dbFilePath];
    
    int ret = sqlite3_open([dbFilePath UTF8String], &db);
    NSAssert1(SQLITE_OK==ret, @"ERROR on opening Database: %s", sqlite3_errmsg(db));
    NSLog(@"Success on Opening Database");
    
    if(NO==existFile){
        const char *createSQL = "CREATE TABLE IF NOT EXISTS MOVIE (TITLE TEXT)";
        char *errorMsg;
        ret=sqlite3_exec(db, createSQL, NULL, NULL, &errorMsg);
        NSLog(@"creating table with ret:%d",ret);
    }
}
-(void)addData:(NSString *)input{
    NSLog(@"adding data:%@",input);
    
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO MOVIE (TITLE) VALUES('%@')",input];
    NSLog(@"sql:%@",sql);
    
    char *errMsg;
    int ret=sqlite3_exec(db, [sql UTF8String], NULL, Nil, &errMsg);
    
    if(SQLITE_OK!=ret){
        NSLog(@"Error on insert data: %s",errMsg);
    }
    [self resolveData];
    
}

-(void)closeData{
    sqlite3_close(db);
}
-(void)resolveData{
    [data removeAllObjects];
    NSString *querystr = @"SELECT rowid,title FROM MOVIE";
    sqlite3_stmt *stmt;
    int ret = sqlite3_prepare_v2(db, [querystr UTF8String], -1, &stmt, NULL);
    NSAssert2(SQLITE_OK==ret, @"Error(%d) on resolving data:%s", ret, sqlite3_errmsg(db));

    while (SQLITE_ROW==sqlite3_step(stmt)) {
        int rowID =sqlite3_column_int(stmt, 0);
        char *title = (char *)sqlite3_column_text(stmt, 1);
        
        movie *one = [[movie alloc]init];
        one.rowID = rowID;
        one.title = [NSString stringWithCString:title encoding:NSUTF8StringEncoding];
        [data addObject:one];
    }
    sqlite3_finalize(stmt);
    [self.table reloadData];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    if([textField.text length]>1){
        [self addData:textField.text];
        [textField resignFirstResponder];
        textField.text=@"";
    }
    return YES;
}
-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if(UITableViewCellEditingStyleDelete==editingStyle){
        movie *one = [data objectAtIndex:indexPath.row];
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM MOVIE WHERE rowid=%d",one.rowID];
        
        char *errMsg;
        int ret = sqlite3_exec(db, [sql UTF8String], NULL, NULL, &errMsg);
        
        if(SQLITE_OK!=ret){
            NSLog(@"Error(%d) on deleting data:%s",ret, errMsg);
            
        }
        [self resolveData];
    }
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [data count];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell*cell=[tableView dequeueReusableCellWithIdentifier:@"CELL_ID"];
    
    movie *one = [data objectAtIndex:indexPath.row];
    cell.textLabel.text = one.title;
    return cell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    data=[NSMutableArray array];
    [self openDB];
}
-(void)viewDidUnload{
    [self setTable:nil];
    [super viewDidUnload];
    [self closeData];
}
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self resolveData];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
