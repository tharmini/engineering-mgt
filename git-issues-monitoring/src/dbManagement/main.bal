//Copyright (c) 2019, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/io;
import ballerina/log;
import ballerina/task;
import ballerina/time;


http:Client gitClientEP = new ("https://api.github.com",
config = {
    followRedirects: {
        enabled: true,
        maxCount: 5
    }
});

task:AppointmentConfiguration appointmentConfiguration = {
    appointmentDetails: CRON_EXPRESSION
};

listener task:Listener appointment = new (appointmentConfiguration);


service appointmentService on appointment {
    resource function onTrigger() {
        updateReposTable();
        log:printInfo("Repo table is updated");
        updateIssuesTable();
        log:printInfo("Issue table is updated");
        InsertIssueCountDetails();
    }
}

type Organization record {
    string OrgName;
};

type LastUpdatedDate record {
    string date;
};

public function main() {
    updateReposTable();
    getAllIssues();
}

//Update the repository table
function updateReposTable() {
    http:Request req = new;
    req.addHeader("Authorization", "token " + AUTH_KEY);
    int orgIterator = 0;
    var organizations = retrieveAllOrganizations();
    if (organizations is json[]) {
        foreach var organization in organizations {
            int pageIterator = 1;
            json[] orgRepos = [];
            boolean isEmpty = false;
            while (!isEmpty) {
                string reqURL = "/users/" + organization.ORG_NAME.toString() + "/repos?&page=" + pageIterator.toString() + "&per_page=100";
                io:println(reqURL);
                var response = gitClientEP->get(reqURL, message = req);
                if (response is http:Response) {
                    int statusCode = response.statusCode;
                    if (statusCode == http:STATUS_OK || statusCode == http:STATUS_MOVED_PERMANENTLY)
                    {
                        var respJson = response.getJsonPayload();
                        if (respJson is json) {
                            json[] repoJson = <json[]>respJson;
                            if (repoJson.length() == 0) {
                                isEmpty = true;
                                io:println(respJson.toString());
                            } else {
                                orgRepos.push(repoJson);
                                io:println(orgRepos.length());
                                storeIntoReposTable(repoJson, <int>organization.ORG_ID);
                            }
                            io:println(isEmpty);
                        }
                    } else {
                        log:printError("Error when calling the github API. StatusCode for the request is " +
                        statusCode.toString() + ". " + response.getJsonPayload().toString());
                    }
                } else {
                    log:printError("Error when calling the backend : " + response.detail().toString());
                }
                pageIterator = pageIterator + 1;
            }
            updateOrgId(orgRepos, <int>organization.ORG_ID);
        }
    } else {
        log:printError("Returned is not a json. Error occured while retrieving the organization details",
        err = organizations);
    }
}

//Update the issue table
function updateIssuesTable() {
    http:Request req = new;
    req.addHeader("Authorization", "token " + AUTH_KEY);
    var organizations = retrieveAllOrganizations();
    if (organizations is json[]) {
        foreach var organization in organizations {
            var repositoryJson = retrieveAllRepos(<int>organization.ORG_ID);
            if (repositoryJson is json[]) {

                if (<int>organization.ORG_ID != -1) {
                    foreach var uuid in repositoryJson {
                        int pageIterator = 1;
                        boolean isEmpty = false;
                        var repositoryId = uuid.REPOSITORY_ID.toString();
                        var lastupdatedDate = githubDb->select(GET_UPDATED_DATE, LastUpdatedDate, repositoryId);
                        string lastUpdated = "";
                        if (lastupdatedDate is table<LastUpdatedDate>) {
                            if (lastupdatedDate.toString() != "") {
                                foreach ( LastUpdatedDate updatedDate in lastupdatedDate) {
                                    io:println(updatedDate.toString());
                                    lastUpdated = updatedDate.date;
                                }
                            } else {
                                lastupdatedDate.close();
                                time:Time time = time:currentTime();
                                time = time:subtractDuration(time, 0, 0, 1, 0, 0, 0, 0);
                                lastUpdated = time:toString(time);
                                io:println("hello outside");
                                io:println(lastUpdated);
                            }
                        } else {
                            log:printError("Error occured while retrieving the last updated date : ", err = lastupdatedDate);
                        }
                        while (!isEmpty) {
                            string reqURL = "/repos/" + organization.ORG_NAME.toString() + "/" +
                            uuid.REPOSITORY_NAME.toString() + "/issues?since=" + <@untainted>lastUpdated + "&state=all&page=" + pageIterator.toString() + "&per_page=100";
                            io:println(reqURL);
                            var response = gitClientEP->get(reqURL, message = req);
                            if (response is http:Response) {
                                int statusCode = response.statusCode;
                                if (statusCode == http:STATUS_OK || statusCode == http:STATUS_MOVED_PERMANENTLY)
                                {
                                    var respJson = response.getJsonPayload();
                                    if (respJson is json) {
                                        json[] repoJson = <json[]>respJson;
                                        if (repoJson.length() == 0) {
                                            io:println("lastupdatedDate empty true", lastupdatedDate);
                                            isEmpty = true;
                                        } else {
                                            io:println("lastupdatedDate is updating", lastupdatedDate);
                                            storeIntoIssueTable(<json[]>respJson, <int>uuid.REPOSITORY_ID);
                                        }
                                    }
                                } else {
                                    log:printError("Error when calling the github API. StatusCode for the request is " +
                                    statusCode.toString() + ". " + response.getJsonPayload().toString());
                                }
                            } else {
                                log:printError("Error when calling backend : " + response.detail().toString());
                            }
                            pageIterator = pageIterator + 1;
                        }
                    }
                }
            } else {
                log:printError("Returned is not a json. Error occured while retrieving repository details: ",
                err = repositoryJson);
            }
        }
    } else {
        log:printError("Error occured while retrieving organization details", err = organizations);
    }
}

//Inserts the issues for the first time
function getAllIssues() {
    http:Request req = new;
    req.addHeader("Authorization", "token " + AUTH_KEY);
    var repositories = retrieveAllReposDetails();
    if (repositories is json[]) {
        foreach var repository in repositories {
            int orgId = <int>repository.ORG_ID;
            if (orgId != -1) {
                var organizationName = githubDb->select(GET_ORG_NAME, Organization, orgId);
                string orgName = "";
                if (organizationName is table<Organization>) {
                    foreach ( Organization org in organizationName) {
                        orgName = org.OrgName;
                    }
                } else {
                    log:printError("Error occured while retrieving the organization name for the given org Id",
                    err = organizationName);
                }
                int repositoryId = <int>repository.REPOSITORY_ID;
                int pageIterator = 1;
                boolean isEmpty = false;
                while (!isEmpty) {
                    string reqURL = "/repos/" + <@untainted>orgName + "/" + repository.REPOSITORY_NAME.toString() +
                    "/issues?state=all&page=" + pageIterator.toString() + "&per_page=100";
                    var response = gitClientEP->get(reqURL, message = req);
                    if (response is http:Response) {
                        int statusCode = response.statusCode;
                        if (statusCode == http:STATUS_OK || statusCode == http:STATUS_MOVED_PERMANENTLY)
                        {
                            var respJson = response.getJsonPayload();
                            if (respJson is json) {
                                json[] repoJson = <json[]>respJson;
                                if (repoJson.length() == 0) {
                                    isEmpty = true;
                                } else {
                                    storeIntoIssueTable(<json[]>respJson, repositoryId);
                                }
                            }
                        } else {
                            log:printError("Error when calling the github API. StatusCode for the request is " +
                            statusCode.toString() + ". " + response.getJsonPayload().toString());
                        }
                    } else {
                        log:printError("Error when calling the backend : " + response.detail().toString());
                    }
                    pageIterator = pageIterator + 1;
                }
            }
        }
    }
}
