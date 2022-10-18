//
// Copyright (c) 2015-Present Oleg Hnidets
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

#import "XCTestCase+Database_Basic.h"

NSString *const kDatabaseName    = @"mysql";
NSString *const kTableName       = @"TestTable";
NSString *const kDropTableString = @"DROP TABLE `TestTable`";

NSString * const kCreateTestTableQuery = @"CREATE TABLE `TestTable` ( `id` mediumint(8) unsigned NOT NULL auto_increment, `name` varchar(255) default NULL, `surname` varchar(255) default NULL, `age` mediumint default NULL, PRIMARY KEY (`id`) ) AUTO_INCREMENT=1; INSERT INTO `TestTable` (`name`,`surname`,`age`) VALUES ('Bradley','Oneill',90),('Levi','Moses',25),('Orlando','Cummings',9),('Hasad','Maldonado',5),('Carlos','Lowery',57),('Axel','Doyle',74),('Hasad','Booth',60),('Hall','Walters',84),('Dustin','Velazquez',84),('Randall','Riggs',91); INSERT INTO `TestTable` (`name`,`surname`,`age`) VALUES ('Harper','Knowles',67),('Jasper','Massey',95),('Hop','Casey',2),('Timon','Bright',25),('Lionel','Mcintyre',74),('Denton','Kennedy',35),('Ethan','Jarvis',43),('Hasad','Stevens',56),('Benedict','Dudley',29),('Shad','Pace',94); INSERT INTO `TestTable` (`name`,`surname`,`age`) VALUES ('Asher','Williamson',70),('Sylvester','Baldwin',37),('Lucas','Bush',62),('Nissim','Harvey',43),('Anthony','Adkins',4),('Norman','Snow',26),('Coby','Oneill',82);";

static NSString *const kEmptyTableString = @"CREATE TABLE `TestTable` ( `id` mediumint(8) unsigned NOT NULL auto_increment, `name` varchar(255) default NULL, `surname` varchar(255) default NOT NULL, `age` mediumint default NULL, PRIMARY KEY (`id`) ) AUTO_INCREMENT=1; INSERT INTO `TestTable` (`name`,`surname`,`age`)";

@implementation XCTestCase (Database_Basic)

- (OHMySQLQueryContext *)mainQueryContext {
    return OHMySQLContainer.shared.mainQueryContext;
}

- (void)setMainQueryContext:(__unused OHMySQLQueryContext *)mainQueryContext {
    NSAssert(NO, @"You must not set this property");
}

- (OHMySQLStoreCoordinator *)storeCoordinator {
    return OHMySQLContainer.shared.storeCoordinator;
}

- (void)setStoreCoordinator:(__unused OHMySQLStoreCoordinator *)storeCoordinator {
    NSAssert(NO, @"You must not set this property");
}

+ (void)configureDatabase {
    NSString *database = @"mysql"; // [NSProcessInfo processInfo].environment[@"DB_NAME"];
    NSString *username = @"root"; // [NSProcessInfo processInfo].environment[@"USER_NAME"];
    NSString *password = @"12345678"; // [NSProcessInfo processInfo].environment[@"USER_PASSWORD"];
    NSString *serverName = @"localhost";  // [NSProcessInfo processInfo].environment[@"DB_HOST"];
    NSString *port = @"3306"; // [NSProcessInfo processInfo].environment[@"DB_PORT"];
    NSString *socket = @"/tmp/mysql.sock"; // [NSProcessInfo processInfo].environment[@"DB_SOCKET"];
    
    OHMySQLConfiguration *user = [[OHMySQLConfiguration alloc] initWithUser:username
                                                                   password:password
                                                                 serverName:serverName
                                                                     dbName:database
                                                                       port:(NSUInteger)[port integerValue]
                                                                     socket:socket];
    OHMySQLStoreCoordinator *coordinator = [[OHMySQLStoreCoordinator alloc] initWithConfiguration:user];
    [coordinator connect];
    
    OHMySQLQueryContext *queryContext = [OHMySQLQueryContext new];
    queryContext.storeCoordinator = coordinator;
    
    OHMySQLContainer.shared.mainQueryContext = queryContext;
}

- (void)createTable {
    [self createTableWithQuery:kCreateTestTableQuery];
}

- (void)createTableWithQuery:(NSString *)query {
    NSString *formattedQuery = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // Table name must be the 3rd word
    NSString *tableName = [formattedQuery componentsSeparatedByString:@" "][2];
    
    // given
    [self dropTableNamed:tableName];
    
    // when
    OHMySQLQueryRequest *queryRequest = [[OHMySQLQueryRequest alloc] initWithQuery:query];
    NSError *error;
    
    BOOL success = [self.mainQueryContext executeQueryRequest:queryRequest error:&error];
    
    // then
    XCTAssert(success && !error);
}

- (void)dropTableNamed:(NSString *)tableName {
    NSString *dropQueryString = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
    OHMySQLQueryRequest *dropQueryRequest =[[OHMySQLQueryRequest alloc] initWithQuery:dropQueryString];
    
    NSError *error;
    [self.mainQueryContext executeQueryRequest:dropQueryRequest error:&error];
}

- (void)createEmptyTable {
    [self createTableWithQuery:@"CREATE TABLE TestTable (`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, `surname` VARCHAR(1) NOT NULL DEFAULT '', `name` VARCHAR(255) NULL, `age` INT NULL, `data` BLOB(20) NULL);"];
}

- (void)clearTableNamed:(NSString *)tableName {
    NSString *deleteQueryString = [NSString stringWithFormat:@"DELETE FROM %@", tableName];
    OHMySQLQueryRequest *dropQueryRequest =[[OHMySQLQueryRequest alloc] initWithQuery:deleteQueryString];
    
    NSError *error;
    [self.mainQueryContext executeQueryRequest:dropQueryRequest error:&error];
}

- (NSNumber *)countOfObjects {
    // given
    OHMySQLQueryRequest *queryRequest = [OHMySQLQueryRequestFactory countAll:kTableName];
    NSError *error;
    
    // when
    NSDictionary *persons = [self.mainQueryContext executeQueryRequestAndFetchResult:queryRequest error:&error].firstObject;
    
    // then
    AssertIfNotDictionary(persons);
    
    // when
    return persons.allValues.firstObject;
}

@end
