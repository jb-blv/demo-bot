*** Settings ***
Documentation     Order robots from https://robotsparebinindustries.com/#/robot-order
...               Get orders file URL from user
...               Download and parse orders file
...               Submit order and make PDF receipt from order summary + robot preview
...               Zip all PDF receipts into one archive
Library           RPA.Browser.Selenium
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Archive
Library           RPA.Robocorp.Vault
Library           Dialogs
Library           RPA.FileSystem

*** Variables ***
# browser cfg
${IMPLICIT_WAIT}=    5 seconds

# filenames
${ORDERS_FILE}=    ${TEMPDIR}${/}orders.csv
${RECEIPTS}=    ${OUTPUT_DIR}${/}receipts.zip

# locators
${OK_BTN}=    xpath://button[text()="OK"]
${HEAD}=    css:#head
${BODY_PARTIAL}=    css:#id-body-
${LEGS}=    css:[placeholder="Enter the part number for the legs"]
${ADDRESS}=    css:#address
${PREVIEW_BTN}=    css:#preview
${ORDER_BTN}=    css:#order
${ROBOT_IMG}=    css:#robot-preview-image
${RECEIPT}=    css:#receipt
${ORDER_ANOTHER_BTN}=    css:#order-another
${ERROR_MSG}=    css:.alert-danger

*** Tasks ***
Order robots on RobotSpareBin Industries Inc.
    ${url}=    Get order URL
    Initialize browser    ${url}
    ${orders}    Get orders
    FOR    ${order}    IN    @{orders}
        Order robot    ${url}    ${order}
    END
    Archive Folder With Zip    ${TEMPDIR}    ${RECEIPTS}    include=*.pdf
    [Teardown]    Close All Browsers

*** Keywords ***
Initialize browser
    [Arguments]    ${url}
    Open Available Browser    ${url}
    Set Browser Implicit Wait    ${IMPLICIT_WAIT}

Get order URL
    ${secret}=    Get Secret    RobotSpareBin
    [Return]    ${secret}[order_url]

# put into assertion library?
Assert expected element exists
    [Arguments]    ${locator}
    Wait Until Element Is Visible    ${locator}

Assert expected conditions
    [Arguments]    ${url}    ${locator}
    Location Should Be    ${url}
    Assert expected element exists    ${locator}

Get orders
    ${url}=    Get orders file URL from user
    Download    ${url}    ${ORDERS_FILE}
    ${orders}=    Read table from CSV    ${ORDERS_FILE}
    [Return]    ${orders}

Get orders file URL from user
    ${orders_file_url}=    Get Value From User    Enter orders file URL
    [Return]    ${orders_file_url}

Order robot
    [Arguments]    ${url}    ${order}
    Assert expected conditions    ${url}    ${ORDER_BTN}
    Run Keyword And Continue On Failure    Close popup
    Fill order    ${order}
    ${img}=    Set Variable    ${TEMP_DIR}${/}${order}[Order number].png
    Get robot image    ${img}
    Generate pdf    ${img}    ${order}[Order number]
    Click Button    ${ORDER_ANOTHER_BTN}

Close popup
    Click Button When Visible    ${OK_BTN}

Fill order
    [Arguments]    ${order}
    Select From List By Value    ${HEAD}    ${order}[Head]
    Click Element    ${BODY_PARTIAL}${order}[Body]
    Input Text    ${LEGS}    ${order}[Legs]
    Input Text    ${ADDRESS}    ${order}[Address]

Get robot image
    [Arguments]    ${img}
    Click Button    ${PREVIEW_BTN}
    Sleep    1    Wait for robot image to fully load
    Screenshot    ${ROBOT_IMG}    ${img}
    Wait Until Created    ${img}

Generate PDF
    [Arguments]    ${img}    ${order_number}
    Wait Until Keyword Succeeds    5x    1.5 sec    Submit order
    ${receipt_html}=    Get Element Attribute    ${RECEIPT}    outerHTML
    Html To Pdf    ${receipt_html}<img src="${img}">
    ...            ${TEMPDIR}${/}${order_number}.pdf

Submit order
    Click Button    ${ORDER_BTN}
    Page Should Not Contain Element    ${ERROR_MSG}