#　PowershellでRedmineを操作するためのスクリプトです。
# 
#　showコマンド
#　　rm_cli.ps1 show
#　　rm_cli.ps1 show [id] [number]
#
#　updateコマンド
#　　rm_cli.ps1 update [id] [notes]

function LoadConfig
{
    
    $xml = [xml](Get-Content .\config.xml)

    $apiKey = $xml.config.apiKey
    $rmUrl = $xml.config.rmUrl
    $rmAssign = $xml.config.rmAssign

    $apiKey,$rmUrl,$rmAssign
}

function ShowIssues
{
    # 設定を取得する
    $config = LoadConfig
    $apiKey = $config[0]
    $rmUrl = $config[1]
    $rmAssign = $config[2]
       
    # アクセスするURLを定義する。
    $request = "$rmUrl/issues.json?key=$apiKey&?assigned_to_id=$rmAssign&limit=100"

    # redmineへアクセスし、JSONを取得する。
    $oXMLHTTP = new-object -com "MSXML2.XMLHTTP.3.0"
    $oXMLHTTP.open("GET","$request","False")
    $oXMLHTTP.send()
    $response = $oXMLHTTP.responseText

    # jsonをパースする。
    Add-Type -AssemblyName System.Web.Extensions
    $serializer=new-object System.Web.Script.Serialization.JavaScriptSerializer
    $obj=$serializer.DeserializeObject($response)

    $i = $obj["issues"].count -1
    while ( $i -ge 0)
    {

        $id = $obj["issues"]["$i"]["id"]    
        $issue = $obj["issues"]["$i"]["subject"]
        $status = $obj["issues"]["$i"]["status"]["name"]
        $project = $obj["issues"]["$i"]["project"]["name"]
        Write-Output "$id `t $project `t $status `t $issue "
        $i = $i - 1 
    }
}

function ShowDetail($id)
{
    # 設定を取得する
    $config = LoadConfig
    $apiKey = $config[0]
    $rmUrl = $config[1]
    $rmAssign = $config[2]
       
    # アクセスするURLを定義する。
    $request = "$rmUrl/issues/$id.json?key=$apiKey&include=journals"

    # redmineへアクセスし、JSONを取得する。
    $oXMLHTTP = new-object -com "MSXML2.XMLHTTP.3.0"
    $oXMLHTTP.open("GET","$request","False")
    $oXMLHTTP.send()
    $response = $oXMLHTTP.responseText

    # jsonをパースする。
    Add-Type -AssemblyName System.Web.Extensions
    $serializer=new-object System.Web.Script.Serialization.JavaScriptSerializer
    $obj=$serializer.DeserializeObject($response)

    $id = $obj["issue"]["id"]    
    $issue = $obj["issue"]["subject"]
    $status = $obj["issue"]["status"]["status"]
    $project = $obj["issue"]["project"]["name"]
    Write-Output "----------------------------------`n Issue `n----------------------------------"
    Write-Output "$id `t $project `t $status `t $issue "

    $i = 0
    Write-Output "----------------------------------`n Detail `n----------------------------------"
    while ( $i -lt $obj["issue"]["journals"].count)
    { 
        $created_on = $obj["issue"]["journals"][$i]["created_on"]
        $name = $obj["issue"]["journals"][$i]["user"]["name"]
        $notes = $obj["issue"]["journals"][$i]["notes"]
        
        Write-Output "$created_on `t $name `t $notes"
        $i++
    }
}

function UpdateIssue($id, $rmNotes)
{   
    # 設定を取得する
    $config = LoadConfig
    $apiKey = $config[0]
    $rmUrl = $config[1]
    $rmAssign = $config[2]

    # アクセスするURLを定義する。
    $request = "$rmUrl/issues/$id.json?key=$apiKey"

    # redmineに送信するjsonを作成する。
    Add-Type -AssemblyName System.Web.Extensions
    $serializer=new-object System.Web.Script.Serialization.JavaScriptSerializer
    $updateJson = $serializer.Serialize(
    @{
    "issue"=
        @{
            "notes"= "$rmNotes" 
        }
    }
    )

    # redmineへアクセスし、JSONをPUTする。
    $oXMLHTTP = new-object -com "MSXML2.XMLHTTP.3.0"
    $oXMLHTTP.open("PUT","$request","False")
    $oXMLHTTP.setRequestHeader("Content-Type","application/json");
    $oXMLHTTP.send( $updateJson )
    $response = $oXMLHTTP.status
    
    if ($response -eq "200"){
        Write-Output "更新が成功しました"
    }else{
        Write-Output "更新が失敗しました"
    }

}

# メイン処理

switch ( $args[0] ){
    # .\rm_cli.ps1 show 
    "show"{ 
        # .\rm_cli.ps1 show [hogehoge]
        switch ( $args[1] ) {
            # .\rm_cli.ps1 show id [hogehoge]
            "id"{
                ShowDetail $args[2]
            }
            # .\rm_cli.ps1 show
            default {
                ShowIssues
            }
        }
    }
    # .\rm_cli.ps1 update id notes
    "update"{
        UpdateIssue $args[1] $args[2]
    }
    default{
        Write-Output "オプションを入力してください。"
    }
}