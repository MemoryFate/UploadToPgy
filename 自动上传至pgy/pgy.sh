#!/bin/bash
#工程名
project_name="HBuilder-Hello"

#获取当前脚本所在目录
SOURCE="$0"
while [ -h "$SOURCE"  ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /*  ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SHELLPATH="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"

#Info.plist路径
INFOPLIST_FILE=${SHELLPATH}/${project_name}/${project_name}-Info.plist

#打包模式 Debug/Release
development_mode=$1

#scheme名
scheme_name="学创在线"
APPLEID="6450803784"
#设置蒲公英参数
user_key=""
api_key=""
#appstore参数
apiKey=""
apiIssuer=""
#证书名
if [[ ${development_mode} = "Debug" ]]; then
    code_sign_identiy="DevelopmentExportOptionsPlist"
elif [[ ${development_mode} = "Release" ]]; then
    code_sign_identiy="DistributionExportOptionsPlist"
else
echo "请输入参数(Debug,Release)"
exit
fi


#plist文件所在路径
if [[ ${development_mode} = "Debug" ]]; then
    exportOptionsPlistPath=${SHELLPATH}/DevelopmentExportOptionsPlist.plist
elif [[ ${development_mode} = "Release" ]]; then
    exportOptionsPlistPath=${SHELLPATH}/DistributionExportOptionsPlist.plist
else
echo "请输入参数(Debug,Release)"
exit
fi

#导出.ipa文件所在路径
exportFilePath=~/Desktop/$scheme_name-$development_mode-$(date "+%Y-%m-%d-%H-%M-%S")

echo "*** 正在清理工程 ***"
xcodebuild clean \
-configuration ${development_mode} -quiet || exit
echo "*** 清理完成 ***"

echo "*** Archive For $development_mode ***"
agvtool next-version
xcodebuild archive \
-project ${project_name}.xcodeproj \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${SHELLPATH}/build/${project_name}.xcarchive \
-quiet || exit
echo "*** Archive完成 ***"

CFBundleVersion=$(/usr/libexec/PlistBuddy -c "Print ApplicationProperties:CFBundleVersion" ${SHELLPATH}/build/${project_name}.xcarchive/Info.plist)
CFBundleIdentifier=$(/usr/libexec/PlistBuddy -c "Print ApplicationProperties:CFBundleIdentifier" ${SHELLPATH}/build/${project_name}.xcarchive/Info.plist)
CFBundleShortVersionString=$(/usr/libexec/PlistBuddy -c "Print ApplicationProperties:CFBundleShortVersionString" ${SHELLPATH}/build/${project_name}.xcarchive/Info.plist)

echo '*** 导出ipa ***'
xcodebuild -exportArchive -allowProvisioningUpdates \
-archivePath ${SHELLPATH}/build/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportFilePath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-destination generic/platform=iOS \
CODE_SIGN_IDENTITY=${code_sign_identiy} \

# 删除build包
if [[ -d build ]]; then
    rm -rf build -r
fi

if [ -e $exportFilePath/$scheme_name.ipa ]; then
    echo "*** ipa已导出 ***"
    cd ${exportFilePath}
    #此处上传分发应用
    if [[ ${development_mode} = "Debug" ]]; then
        echo "*** 上传至蒲公英 ***"
        RESULT=$(curl -F "file=@${scheme_name}.ipa" \
        -F "uKey=$user_key" \
        -F "_api_key=$api_key" \
        -F "publishRange=2" http://www.pgyer.com/apiv1/app/upload)
        echo $RESULT | jq .
        echo "*** .ipa文件上传蒲公英成功 ***"
    elif [[ ${development_mode} = "Release" ]]; then
        echo "*** 应用验证 ***"
        
        xcrun altool --validate-app \
        -f ${scheme_name}.ipa \
        -t ios \
        --apiKey ${apiKey} \
        --apiIssuer ${apiIssuer} \
        --show-progress \
        --output-format json | jq .
        
        if [[ $? -eq 1 ]]; then
            echo "*** 验证失败 ***"
            exit
        else
            echo "*** 上传至App Store Connect ***"
            xcrun altool --upload-package \
            ${scheme_name}.ipa \
            -t ios \
            --apiKey ${apiKey} \
            --apiIssuer ${apiIssuer} \
            --apple-id $APPLEID\
            --bundle-id $CFBundleIdentifier \
            --bundle-short-version-string $CFBundleShortVersionString \
            --bundle-version $CFBundleVersion \
            --show-progress \
            --output-format json | jq .
        fi
    else
        exit
    fi
    
else
    echo "*** 创建.ipa文件失败 ***"
fi
echo '*** 打包完成 ***'
