import sys
import io
from pathlib import Path

# Fix Windows console UTF-8 output
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from backend.app.chatbot_service import get_chatbot_response

def test_chatbot():
    print("Testing SkinCore Chatbot Service with Groq LLM...")
    
    test_queries = [
        "how distionguish between benign and harmful cysts",
        "How do I take a good skin scan?",
        "What is the best daily routine for acne?"
    ]

    for q in test_queries:
        print(f"\n=======================================================")
        print(f"User Query: '{q}'")
        reply, model = get_chatbot_response(q)
        print(f"Model Used: {model}")
        print(f"Full Reply:\n{reply}")
        print(f"=======================================================\n")

if __name__ == "__main__":
    test_chatbot()
