# UploadToPgy
自动上传至蒲公英

## 使用方法非常简单  
1.将脚本和两个plist文件拷贝到项目的根目录下（也就是说和*.xcodeproj同一层级）  
2.打开终端（terminal）输入`sh pgy.sh Debug`即可  
ipa文件默认放在桌面上  
# #
<font color=#ff0000>注意事项：</font>
1.shell脚本中需要手动输入你的项目名称和scheme名称，否则无法执行  
2.shell代码的第15行是设置Info.plist路径的，如果路径不一致可以自行修改  
3.文件中需要设置蒲公英参数`user_key=""`和`api_key=""`  
