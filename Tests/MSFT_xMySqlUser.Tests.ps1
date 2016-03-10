$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (! (Get-Module xDSCResourceDesigner))
{
    Import-Module -Name xDSCResourceDesigner
}

Describe 'Schema Validation MSFT_xMySqlUser' {
    It 'should pass Test-xDscResource' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xMySqlUser'
        $result = Test-xDscResource $path
        $result | Should Be $true
    }

    It 'should pass Test-xDscSchema' {
        $path = Join-Path -Path $((get-item $here).parent.FullName) -ChildPath 'DSCResources\MSFT_xMySqlUser\MSFT_xMySqlUser.schema.mof'
        $result = Test-xDscSchema $path
        $result | Should Be $true
    }
}

if (Get-Module MSFT_xMySqlUser)
{
    Remove-Module MSFT_xMySqlUser
}

if (Get-Module xMySql)
{
    Remove-Module xMySql
}

if (Get-Module MSFT_xMySqlUtilities)
{
    Remove-Module MSFT_xMySqlUtilities
}

Import-Module (Join-Path $here -ChildPath "..\MSFT_xMySqlUtilities.psm1")
Import-Module (Join-Path $here -ChildPath "..\DSCResources\MSFT_xMySqlUser\MSFT_xMySqlUser.psm1")

$DSCResourceName = "MSFT_xMySqlUser"
InModuleScope $DSCResourceName {

    $testPassword = ConvertTo-SecureString "password" -AsPlainText -Force
    $testCred = New-Object -typename System.Management.Automation.PSCredential -argumentlist "account",$testPassword

    Describe "how Get-TargetResource works" {
        $userName = "TestUser"

        Context 'when ErrorPath exists' {

            Mock Test-Path -Verifiable { return $true }
            Mock Remove-Item -Verifiable { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return "Yes" }
            Mock Read-ErrorFile -Verifiable { return }

            $result = Get-TargetResource -UserName $userName -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
        }

        Context 'when ErrorPath does not exist' {

            Mock Test-Path -Verifiable { return $false }
            Mock Remove-Item { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return "Yes" }
            Mock Read-ErrorFile -Verifiable { return }

            $result = Get-TargetResource -UserName $userName -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should not call all the mocks' {
                Assert-VerifiableMocks
                Assert-MockCalled Remove-Item 0
            }
        }

        Context 'when the given local user exists' {

            Mock Test-Path -Verifiable { return $true }
            Mock Remove-Item -Verifiable { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return "Yes" }
            Mock Read-ErrorFile -Verifiable { return }

            $result = Get-TargetResource -UserName $userName -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
            It 'Ensure should be Present' {
                $result['Ensure'] | should be 'Present'
            }
            It "UserName should be $userName" {
                $result['UserName'] | should be $userName
            }
            It "HostName should be localhost" {
                $result['HostName'] | should be 'localhost'
            }
        }

        Context 'when the given local user does not exist' {

            Mock Test-Path -Verifiable { return $true }
            Mock Remove-Item -Verifiable { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return "No" }
            Mock Read-ErrorFile -Verifiable { return }
            
            $result = Get-TargetResource -UserName $userName -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
            It 'Ensure should be Absent' {
                $result['Ensure'] | should be 'Absent'
            }
            It "UserName should be $userName" {
                $result['UserName'] | should be $userName
            }
            It "HostName should be localhost" {
                $result['HostName'] | should be 'localhost'
            }
        }
        
        Context 'when given a remote user' {
            $testUserName = $userName
            $testHostName = "%"

            Mock Test-Path { return $true }
            Mock Remove-Item {}
            Mock Get-MySqlPort { return "3306" }
            Mock Get-MySqlExe { return "C:\Program Files\MySQL\MySQL Server 5.6\bin\mysql.exe" }
            Mock Invoke-MySqlCommand { return "Yes" }
            Mock Read-ErrorFile {}

            $result = Get-TargetResource -UserName $testUserName -HostName $testHostName -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It "should call Invoke-MySqlCommand with his/her UserName and HostName" {
                Assert-MockCalled Invoke-MySqlCommand -ParameterFilter {
                    ($Arguments -match "USER = '$testUserName'") -and ($Arguments -match "HOST = '$testHostName'")
                }
            }
        }
    }

    Describe "how Test-TargetResource works when Ensure is 'Present'" {
        Context 'when the given local user exists' {
            $userExists = @{
                Ensure = "Present"
                UserName = "TestUser"
            }

            Mock Get-TargetResource -Verifiable { return $userExists }
            
            $result = Test-TargetResource -UserName "TestUser" -Ensure "Present" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
            It 'should return true' {
                $result | should be $true
            }
        }

        Context 'when the given local user does not exist' {
            $userNotExist = @{
                Ensure = "Absent"
                UserName = "TestUser"
            }

            Mock Get-TargetResource -Verifiable { return $userNotExist }
            
            $result = Test-TargetResource -UserName "TestUser" -Ensure "Present" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
            It 'should return false' {
                $result | should be $false
            }
        }
    }

    Describe "how Test-TargetResource works when Ensure is 'Absent'" {
        Context 'when the given local user exists' {
            $userExists = @{
                Ensure = "Present"
                UserName = "TestUser"
            }

            Mock Get-TargetResource -Verifiable { return $userExists }
            
            $result = Test-TargetResource -UserName "TestUser" -Ensure "Absent" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
            It 'should return false' {
                $result | should be $false
            }
        }

        Context 'when the given local user does not exist' {
            $userNotExist = @{
                Ensure = "Absent"
                UserName = "TestUser"
            }

            Mock Get-TargetResource -Verifiable { return $userNotExist }
            
            $result = Test-TargetResource -UserName "TestUser" -Ensure "Absent" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
            It 'should return true' {
                $result | should be $true
            }
        }
    }

    Describe 'how Set-TargetResource works' {
        Context "when ErrorPath exists" {

            Mock Test-Path -Verifiable { return $true }
            Mock Remove-Item -Verifiable { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return } -ParameterFilter { $arguments -match "CREATE" }
            Mock Read-ErrorFile -Verifiable { return }

            $null = Set-TargetResource -UserName "TestUser" -Ensure "Present" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
        }

        Context "when ErrorPath does not exist" {

            Mock Test-Path -Verifiable { return $false }
            Mock Remove-Item { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return } -ParameterFilter { $arguments -match "CREATE" }
            Mock Read-ErrorFile -Verifiable { return }

            $null = Set-TargetResource -UserName "TestUser" -Ensure "Present" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should not call all the mocks' {
                Assert-VerifiableMocks
                Assert-MockCalled Remove-Item 0
            }
        }

        Context "when Ensure is 'Present'" {

            Mock Test-Path -Verifiable { return $true }
            Mock Remove-Item -Verifiable { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return } -ParameterFilter { $arguments -match "CREATE" }
            Mock Read-ErrorFile -Verifiable { return }
            
            $null = Set-TargetResource -UserName "TestUser" -Ensure "Present" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
        }

        Context "when Ensure is 'Absent'" {

            Mock Test-Path -Verifiable { return $true }
            Mock Remove-Item -Verifiable { return }
            Mock Get-MySqlPort -Verifiable { return "3306" }
            Mock Get-MySqlExe -Verifiable { return "C:\somepath" }
            Mock Invoke-MySqlCommand -Verifiable { return } -ParameterFilter { $arguments -match "DROP" }
            Mock Read-ErrorFile -Verifiable { return }

            $null = Set-TargetResource -UserName "TestUser" -Ensure "Absent" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It 'should call all the mocks' {
                Assert-VerifiableMocks
            }
        }
        
        Context 'when given a remote user' {
            $testUserName = "TestUser"
            $testHostName = "%"

            Mock Test-Path { return $true }
            Mock Remove-Item {}
            Mock Get-MySqlPort { return "3306" }
            Mock Get-MySqlExe { return "C:\Program Files\MySQL\MySQL Server 5.6\bin\mysql.exe" }
            Mock Invoke-MySqlCommand { return "Yes" }
            Mock Read-ErrorFile {}

            Set-TargetResource -UserName $testUserName -HostName $testHostName -Ensure "Present" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"
            Set-TargetResource -UserName $testUserName -HostName $testHostName -Ensure "Absent" -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It "should call Invoke-MySqlCommand with his/her UserName and HostName" {
                Assert-MockCalled Invoke-MySqlCommand -Times 2 -ParameterFilter {
                    ($Arguments -match "USER '$testUserName'@'$testHostName'")
                }
            }
        }
    }
    
    Describe "Test-TargetResource" {
        Context "given a remote user" {
            $testUserName = "TestUser"
            $testHostName = "%"
            $testEnsure = "Absent"

            Mock Get-TargetResource { return @{ Ensure = $testEnsure; UserName = $testUserName } }

            $result = Test-TargetResource -UserName $testUserName -HostName $testHostName -Ensure $testEnsure -UserPassword $testCred -RootPassword $testCred -MySqlVersion "5.6.17"

            It "should call Get-TargetResource with his/her UserName and HostName" {
                Assert-MockCalled Get-TargetResource -ParameterFilter {
                    ($UserName -eq "$testUserName") -and ($HostName -eq "$testHostName")
                }
            }
        }
    }
}