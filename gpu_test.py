import tensorflow as tf

print("TensorFlow:", tf.__version__)
print("Built with CUDA:", tf.test.is_built_with_cuda())
print("GPU support:", tf.test.is_built_with_gpu_support())
print("GPUs:", tf.config.list_physical_devices('GPU'))