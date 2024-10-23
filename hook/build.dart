import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:flutter_gpu_shaders/build.dart';
import 'package:flutter_scene_importer/build_hooks.dart';


void main(List<String> args) async {

    await buildGPUTriangle(args);
    await buildFlutterHelment(args);
}


Future buildGPUTriangle(List<String> args) async {
    await build(args, (config, output) async {
    await buildShaderBundleJson(
        buildConfig: config,
        buildOutput: output,
        manifestFileName: 'my_renderer.shaderbundle.json');
  });
}


Future buildFlutterHelment(List<String> args) async {
  build(args, (config, output) async {
    buildModels(buildConfig: config, inputFilePaths: [
      'DamagedHelmet.glb',
    ]);
  });
}
