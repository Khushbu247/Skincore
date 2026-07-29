from backend.app.predictor import predict_image

IMAGE_PATH = "backend/uploads/test.jpg"

result = predict_image(IMAGE_PATH)

print(result)