import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { productViewManager, updateManager } from '@kit.StoreKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { bundleManager, common, UIAbility, Want } from '@kit.AbilityKit';
import { fileUri, picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { filePreview } from '@kit.PreviewKit';
import featureAbility from '@ohos.ability.featureAbility';

/** FlutterOhosUtilsPlugin **/
export default class FlutterOhosUtilsPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware {
  private channel: MethodChannel | null = null;
  private context: common.UIAbilityContext | null = null;

  constructor() {
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onDetachedFromAbility(): void {
    this.context = null;
  }

  getUniqueClassName(): string {
    return "FlutterOhosUtilsPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "flutter_ohos_utils");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
  }

  getBundleInfo(): bundleManager.BundleInfo {
    return bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if(call.method == "getBundleInfo"){
      result.success(this.getBundleInfo());
    }
    else if (call.method == "gotoAppStore") {
      let bundleName:string|null = call.args;
      if(!bundleName) {
        let bundleInfo = this.getBundleInfo();
        bundleName = bundleInfo.name;
        console.debug(`bundle Info = ${JSON.stringify(bundleInfo)}`);
      }
      this.onGotoAppStore(bundleName, result);
    } else if(call.method == "checkUpdate") {
      this.onCheckUpdate(result);
    } else if(call.method == "showUpdateDialog") {
      this.onShowUpdateDialog(result);
    } else if(call.method == "openWant") {
      let want: Want = {};
      want.bundleName = call.argument('bundleName');
      want.abilityName = call.argument('abilityName');
      want.deviceId = "";
      want.uri = call.argument('uri');
      want.type = call.argument('type');
      want.flags = call.argument('flags');
      want.action = call.argument('action');
      want.moduleName = call.argument('moduleName');
      want.parameters = call.argument('parameters');
      want.entities = call.argument('entities');
      this.onOpenWant(want, result);
    } else if(call.method == "saveDocument") {
      let fileName: string = call.argument('fileName');
      let fileExt: string = call.argument('fileExt');
      let fileBytes: Uint8Array = call.argument('fileBytes');
      this.onSaveDocument(result, fileName, fileExt, fileBytes);
    } else if(call.method == "previewFile") {
      let title: string = call.argument('title');
      let path: string = call.argument('path');
      let mimeType: string = call.argument('mimeType');
      this.onPreviewFile(result, title, path, mimeType);
    }
    else {
      result.notImplemented()
    }
  }

  onPreviewFile(result: MethodResult, title: string, path: string, mimeType: string) {
    let uri = new fileUri.FileUri(path);
    let fileInfo: filePreview.PreviewInfo = {
      title: title,
      uri: uri.toString(),
      mimeType: mimeType
    };
    if(fs.accessSync(path)) {
      filePreview.openPreview(this.context, fileInfo).then(() => {
        console.info('Succeeded in opening preview');
        result.success(true);
      }).catch((err: BusinessError) => {
        console.error(`Failed to open preview, err.code = ${err.code}, err.message = ${err.message}`);
        result.error(`Failed to open preview, err.code = ${err.code}, err.message = ${err.message}`, '', '');
      });
    } else {
      console.error(`file not access:${path}`);
    }


  }

  onSaveDocument(result: MethodResult, fileName: string, fileExt: string, fileBytes: Uint8Array) {
    // 创建文件管理器选项实例
    const documentSaveOptions = new picker.DocumentSaveOptions();
    // // 保存文件名（可选）
    // documentSaveOptions.newFileNames = [fileName];
    // // // 保存文件类型['后缀类型描述|后缀类型'],选择所有文件：'所有文件(*.*)|.*'（可选） ，如果选择项存在多个后缀，默认选择第一个。
    // documentSaveOptions.fileSuffixChoices = [`.${fileExt}`];
    // 请确保 getContext(this) 返回结果为 UIAbilityContext
    documentSaveOptions.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
    let context = getContext(this) as common.Context;


    // 创建文件选择器实例。
    const documentViewPicker = new picker.DocumentViewPicker(context);
    //用户选择目标文件夹，用户选择与文件类型相对应的文件夹，即可完成文件保存操作。保存成功后，返回保存文档的URI。
    documentViewPicker.save(documentSaveOptions).then((documentSaveResult: Array<string>) => {
      let cachePath = context.cacheDir + '/' + fileName + '.' + fileExt;
      let file = fs.openSync(cachePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let writeLen: number = fs.writeSync(file.fd, fileBytes.buffer);
      console.info(`sandbox writeLen:${writeLen}}`);
      fs.closeSync(file);

      let uriString = new fileUri.FileUri(documentSaveResult[0]);
      let destPath = uriString.path + '/' + fileName + '.' + fileExt;
      let n: number = 1;
      while(fs.accessSync(destPath)) {
        destPath = uriString.path + '/' + fileName + `(${n}).` + fileExt;
        n++;
        console.info(`destPath=${destPath}}`);
      }
      // console.info(`destPath=${destPath}`);
      fs.copyFileSync(cachePath, destPath ,0);
      fs.access(destPath).then((value)=>{
        console.info(`value=${value}`);
      }).catch((error: BusinessError)=>{
        console.error(`code=${error.code}}, name=${error.name}, message=${error.message}`);
      });
      console.info('copy done');

      // let uri = documentSaveResult[0];
      //
      // //这里需要注意接口权限参数是fs.OpenMode.READ_WRITE。
      // let file = fs.openSync(uri, fs.OpenMode.READ_WRITE);
      // console.info('file fd: ' + file.fd);
      // let writeLen: number = fs.writeSync(file.fd, fileBytes.buffer);
      // console.info('write data to file succeed and size is:' + writeLen);
      // fs.closeSync(file);
      result.success(destPath);
    }).catch((err: BusinessError) => {
      result.error(`${err.code}`, `${err.message}`, null);
      console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
    })
  }

  onCheckUpdate(result: MethodResult) {
    try{
      updateManager.checkAppUpdate(this.context).then((checkResult: updateManager.CheckUpdateResult)=>{
        result.success(checkResult.updateAvailable == updateManager.UpdateAvailableCode.LATER_VERSION_EXIST);
      }).catch((error:BusinessError)=>{
        console.debug(`catch error:${JSON.stringify(error)}`);
        result.error(error.code.toString(), `message: ${error.message}`, `stack: ${error.stack}`);
      });
    } catch(err) {
      console.debug(`check error:${JSON.stringify(err)}`);
      result.error('00001', `message: ${JSON.stringify(err)}`, null);
    }
  }

  onShowUpdateDialog(result: MethodResult) {
    try{
      updateManager.showUpdateDialog(this.context).then((resultCode: updateManager.ShowUpdateResultCode)=>{
        result.success(resultCode == updateManager.ShowUpdateResultCode.SHOW_DIALOG_SUCCESS);
      }).catch((error:BusinessError)=>{
        console.debug(`catch error=${JSON.stringify(error)}`);
        result.error(error.code.toString(), `message: ${error.message}`, `stack: ${error.stack}`);
      });
    } catch(err) {
      console.debug(`show dialog error:${JSON.stringify(err)}`);
      result.error('00001', `message: ${JSON.stringify(err)}`, null);
    }
  }

  onOpenWant(want:Want, result:MethodResult) {
    console.debug(`will start ability, want = ${JSON.stringify(want)}`);
    try{
      this.context?.startAbilityForResult(want, (error: BusinessError, r: common.AbilityResult)=>{
        if(error.code) {
          console.debug(`error: ${JSON.stringify(error)}`);
          result.error('1', 'start ability failed', JSON.stringify(error));
        } else {
          console.debug(`start ability success :${JSON.stringify(r)}`);
          result.success('start ability success');
        }
      });
    } catch(error) {
      console.debug(`params error:${JSON.stringify(error)}`);
      result.error('2', 'params error', JSON.stringify(error));
    }
  }

  onGotoAppStore(bundleName: string, result: MethodResult) {
    let want:Want = {
      parameters: {
        bundleName: bundleName
      }
    };
    productViewManager.loadProduct(this.context, want, {
      onError: (error: BusinessError)=> {
        console.debug(`load product error:${JSON.stringify(error)}`);
      }
    });
    result.success(1);
  }
}