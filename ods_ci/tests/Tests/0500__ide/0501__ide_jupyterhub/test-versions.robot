*** Settings ***
Documentation       Test Suite to verify installed library versions.
...                 It tests only the latest versions of the images.

Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource            ../../../Resources/Page/OCPDashboard/Builds/Builds.robot
Library             JupyterLibrary

Suite Setup         Load Spawner Page
Suite Teardown      End Web Test

Test Tags          JupyterHub


*** Variables ***
@{status_list}      # robocop: disable
&{package_versions}      # robocop: disable
${JupyterLab_Version}         v4.2
${JupyterLab-git_Version}     v0.50


*** Test Cases ***
Open JupyterHub Spawner Page
    [Documentation]    Verifies that Spawner page can be loaded
    [Tags]    Tier1
    ...       ODS-695
    Pass Execution    Passing tests, as suite setup ensures that spawner can be loaded

Verify Libraries in Minimal Image
    [Documentation]    Verifies libraries in Minimal Python image
    [Tags]    Tier1
    Verify List Of Libraries In Image    minimal-notebook    JupyterLab-git ${JupyterLab-git_Version}

Verify Libraries in Cuda Image
    [Documentation]    Verifies libraries in Cuda image
    [Tags]    Tier1
    Verify List Of Libraries In Image    minimal-gpu    JupyterLab-git ${JupyterLab-git_Version}

Verify Libraries in SDS Image
    [Documentation]    Verifies libraries in Standard Data Science image
    [Tags]    Tier1
    Verify List Of Libraries In Image    science-notebook    JupyterLab ${JupyterLab_Version}
    ...    JupyterLab-git ${JupyterLab-git_Version}

Verify Libraries in PyTorch Image
    [Documentation]    Verifies libraries in PyTorch image
    [Tags]    Tier1
    ...       ODS-215    ODS-216    ODS-217    ODS-218    ODS-466
    Verify List Of Libraries In Image
    ...    pytorch    JupyterLab ${JupyterLab_Version}    JupyterLab-git ${JupyterLab-git_Version}

Verify Libraries in Tensorflow Image
    [Documentation]    Verifies libraries in Tensorflow image
    [Tags]    Tier1
    ...       ODS-204    ODS-205    ODS-206    ODS-207  ODS-474
    Verify List Of Libraries In Image
    ...    tensorflow    JupyterLab ${JupyterLab_Version}    JupyterLab-git ${JupyterLab-git_Version}

Verify Libraries in TrustyAI Image
    [Documentation]    Verifies libraries in TrustyAI image
    [Tags]    Tier1
    Verify List Of Libraries In Image
    ...    odh-trustyai-notebook    JupyterLab ${JupyterLab_Version}    JupyterLab-git ${JupyterLab-git_Version}

Verify All Images And Spawner
    [Documentation]    Verifies that all images have the correct libraries with same versions
    [Tags]    Tier1
    ...       ODS-340    ODS-452    ODS-468
    List Should Not Contain Value    ${status_list}    FAIL
    ${length} =    Get Length    ${status_list}
    Should Be Equal As Integers    ${length}    6
    Log To Console    ${status_list}


*** Keywords ***
Verify Libraries In Base Image    # robocop: disable
    [Documentation]    Fetches library versions from JH spawner and checks
    ...    they match the installed versions.
    [Arguments]    ${img}    ${additional_libs}
    @{list} =    Create List
    ${text} =    Fetch Image Description Info    ${img}
    Append To List    ${list}    ${text}
    ${tmp} =    Fetch Image Tooltip Info    ${img}
    ${list} =    Combine Lists    ${list}    ${tmp}    # robocop: disable
    ${list} =    Combine Lists    ${list}    ${additional_libs}
    Log    ${list}
    Spawn Notebook With Arguments    image=${img}
    ${status} =    Check Versions In JupyterLab    ${list}
    Clean Up Server
    Stop JupyterLab Notebook Server
    Go To    ${ODH_DASHBOARD_URL}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Fix Spawner Status
    Wait Until JupyterHub Spawner Is Ready
    RETURN    ${status}

Load Spawner Page
    [Documentation]    Suite Setup, loads JH Spawner
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard

Verify List Of Libraries In Image
    [Documentation]    It checks that libraries are installed or not in ${image} image
    [Arguments]    ${image}    @{additional_libs}
    ${status} =    Verify Libraries In Base Image    ${image}    ${additional_libs}
    Append To List    ${status_list}    ${status}
    IF    '${status}' == 'FAIL'    Fail    Shown and installed libraries for ${image} image do not match

