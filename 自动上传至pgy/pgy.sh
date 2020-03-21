#!/bin/bash
#工程名
project_name="工程名"

#获取当前脚本所在目录
SOURCE="$0"
while [ -h "$SOURCE"  ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /*  ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
SHELLPATH="$( cd -P "$( dirname "$SOURCE"  )" && pwd  )"

#Info.plist路径
INFOPLIST_FILE=${SHELLPATH}/${project_name}/Info.plist
#版本号自增
buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" ${INFOPLIST_FILE})
buildNumber=$(($buildNumber + 1))
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "$INFOPLIST_FILE"
#打包模式 Debug/Release
development_mode=$1

#scheme名
scheme_name="scheme名"

#设置蒲公英参数
user_key=""
api_key=""

#证书名
# if [ ${development_mode} = "Debug" ]; then
#     code_sign_identiy=""
# else
#     code_sign_identiy="上传证书名"
# fi

#provisioning file名称
# if [ ${development_mode} = "Debug" ]; then
#    provisioning_file=""
# else
#     provisioning_file="上传配置文件名"
# fi

#plist文件所在路径
if [ ${development_mode} = "Debug" ]; then
    exportOptionsPlistPath=${SHELLPATH}/DevelopmentExportOptionsPlist.plist
else
    exportOptionsPlistPath=${SHELLPATH}/DistributionExportOptionsPlist.plist
fi

#导出.ipa文件所在路径
exportFilePath=~/Desktop/$project_name-$development_mode-$(date "+%Y-%m-%d_%H\:%M\:%S")

echo '*** 正在清理工程 ***'
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit 
echo '*** 清理完成 ***'


echo '*** 正在编译工程 For '${development_mode}
xcodebuild \
archive -workspace ${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${SHELLPATH}/build/${project_name}.xcarchive \
-quiet || exit
echo '*** 编译完成 ***'


echo '*** 正在打包 ***'
xcodebuild -exportArchive -archivePath ${SHELLPATH}/build/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportFilePath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
# CODE_SIGN_IDENTITY=${code_sign_identiy} \
# PROVISIONING_PROFILE=${provisioning_file}

# 删除build包
if [[ -d build ]]; then
    rm -rf build -r
fi

if [ -e $exportFilePath/$scheme_name.ipa ]; then
    echo "*** .ipa文件已导出 ***"
    cd ${exportFilePath}
    echo "*** 开始上传.ipa文件 ***"
    #此处上传分发应用
    RESULT=$(curl -F "file=@${scheme_name}.ipa" \
    -F "uKey=$user_key" \
    -F "_api_key=$api_key" \
    -F "publishRange=2" http://www.pgyer.com/apiv1/app/upload) 
    echo "*** .ipa文件上传蒲公英成功 ***"
    echo $RESULT
else
    echo "*** 创建.ipa文件失败 ***"
fi
echo '*** 打包完成 ***'
