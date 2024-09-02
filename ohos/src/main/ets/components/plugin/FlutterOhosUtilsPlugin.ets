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
    }
    else {
      result.notImplemented()
    }
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