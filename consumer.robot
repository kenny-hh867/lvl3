*** Settings ***
Documentation       Inhuman Insurance, Inc. Artificial Intelligence System robot.
...                 Consumes traffic data work items.

Resource            shared.robot
Library             RPA.HTTP


*** Tasks ***
Consume traffic data work items
    For Each Input Work Item    Process traffic data


*** Keywords ***
Process traffic data
    ${payload}=    Get Work Item Payload
    ${traffic_data}=    Set Variable    ${payload}[${WORK_ITEM_NAME}]
    ${valid}=    Validate traffic data    ${traffic_data}
    IF    ${valid}
        Post traffic data to sales system    ${traffic_data}
    ELSE
        Handle invalid traffic data    ${traffic_data}
    END

Validate traffic data
    [Arguments]    ${traffic_data}
    ${country}=    Get value from JSON    ${traffic_data}    country    #$.country???
    ${valid}=    Evaluate    len("${country}") == 3
    RETURN    ${valid}

Post traffic data to sales system
    [Arguments]    ${traffic_data}
    ${status}    ${return}=    Run Keyword And Ignore Error
    ...    POST
    ...    https://robocorp.com/inhuman-insurance-inc/sales-system-api
    ...    json=${traffic_data}
    Handle traffic API response    ${status}    ${return}    ${traffic_data}

Handle traffic API response
    [Arguments]    ${status}    ${return}    ${traffic_data}
    IF    "${status}" == "PASS"
        Release Input Work Item    DONE
    ELSE
        Log
        ...    Traffic data posting failed: ${traffic_data} ${return}
        ...    ERROR
        Release Input Work Item
        ...    state=FAILED
        ...    exception_type=APPLICATION
        ...    code=TRAFFIC_DATA_POST_FAILED
        ...    message=${return}
    END

Handle invalid traffic data
    [Arguments]    ${traffic_data}
    ${message}=    Set Variable    Invalid traffic data: ${traffic_data}
    Log    ${message}    WARN
    Release Input Work Item
    ...    state=FAILED
    ...    exception_type=BUSINESS
    ...    code=INVALID_TRAFFIC_DATA
    ...    message=${message}
