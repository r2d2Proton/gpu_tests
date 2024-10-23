import 'dart:math';
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';

import 'package:flutter/material.dart';
import 'package:flutter_gpu/gpu.dart' as gpu;

import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/camera.dart';
import 'package:flutter_scene/node.dart';
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart';

// NOTE: We made this earlier while setting up shader bundle imports!
import 'shaders.dart';

import 'package:flutter/src/material/colors.dart' as colors;


void main() {
  runApp(const MyApp());
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}


class MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  double elapsedSeconds = 0;
  Scene scene = Scene();

  @override
  Widget build(BuildContext context) {
    final painter = ScenePainter(
      scene: scene,
      camera: PerspectiveCamera(
        position: Vector3(sin(elapsedSeconds) * 3, 2, cos(elapsedSeconds) * 3),
        target: Vector3(0, 0, 0),
      ),
    );

    return MaterialApp(
      title: 'My 3D app',
      home: CustomPaint(painter: painter),
    );
  }


  @override
  void initState() {
    
    createTicker((elapsed) {
      setState(() {
        elapsedSeconds = elapsed.inMilliseconds.toDouble() / 1000;
      });
    }).start();

    Node.fromAsset('build/models/DamagedHelmet.model').then((model) {
      model.name = 'Helmet';
      scene.add(model);
    });
        
    super.initState();
  }
}


class ScenePainter extends CustomPainter {

  ScenePainter({required this.scene, required this.camera});
  Scene scene;
  Camera camera;
  
  
  @override
  void paint(Canvas canvas, Size size) {

    scene.render(camera, canvas, viewport: Offset.zero & size);

    Vector4? clearColor = Vector4(colors.Colors.lightBlue.r, colors.Colors.lightBlue.g, colors.Colors.lightBlue.b, colors.Colors.lightBlue.a);
    //final texture = gpu.gpuContext.createTexture(gpu.StorageMode.devicePrivate, size.width.toInt(), size.height.toInt())!;
    final texture = gpu.gpuContext.createTexture(gpu.StorageMode.hostVisible, size.width.toInt(), size.height.toInt())!;
    final renderTarget = gpu.RenderTarget.singleColor(gpu.ColorAttachment(texture: texture, clearValue: clearColor));

    final commandBuffer = gpu.gpuContext.createCommandBuffer();
    final renderPass = commandBuffer.createRenderPass(renderTarget);
    // ... draw calls will go here!
    final vert = shaderLibrary['SimpleVertex']!;
    final frag = shaderLibrary['SimpleFragment']!;
    final pipeline = gpu.gpuContext.createRenderPipeline(vert, frag);

    final vertices = Float32List.fromList([
      -0.5, -0.5, // First vertex
      0.5, -0.5, // Second vertex
      0.0,  0.5, // Third vertex
    ]);

    final verticesDeviceBuffer = gpu.gpuContext.createDeviceBufferWithCopy(ByteData.sublistView(vertices))!;
    renderPass.bindPipeline(pipeline);

    final verticesView = gpu.BufferView(verticesDeviceBuffer, offsetInBytes: 0, lengthInBytes: verticesDeviceBuffer.sizeInBytes,);
    renderPass.bindVertexBuffer(verticesView, 3);

    renderPass.draw();
    
    commandBuffer.submit();

    final image = texture.asImage();
    canvas.drawImage(image, Offset.zero, Paint());
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
