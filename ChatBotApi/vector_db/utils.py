from dotenv import load_dotenv
import os
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
from qdrant_client.models import VectorParams, Distance
import uuid

load_dotenv('./config.env')

VECTOR_DB_KEY = os.getenv("VECTOR_DB_KEY")
QDRANT_URL = os.getenv("QDRANT_URL")

client = QdrantClient(url=QDRANT_URL,api_key=VECTOR_DB_KEY)
# print(QDRANT_URL,VECTOR_DB_KEY)

def insert_data(collection_name, vector, payload):
    if not client.collection_exists(collection_name):
        client.create_collection(
            collection_name=collection_name,
            vectors_config=VectorParams(
                size=768,           # Dimension of your vectors
                distance=Distance.COSINE  # Specify the distance metric
            )
        )
    # print(type(vector),type(payload))
    client.upsert(
        collection_name=collection_name,
        points=[
            PointStruct(
                id=str(uuid.uuid4()),  # Generate a unique ID
                vector=vector,  
                payload=payload,         # Metadata for the vector
            )
        ]
    )

def retrieve_data(collection_name, query_vector, top_k=5):
    # Perform a search for the nearest vectors in the collection
    results = client.search(
        collection_name=collection_name,
        query_vector=query_vector,  # The vector to search for similarity
        limit=top_k,                  # The number of nearest neighbors to retrieve
        with_payload=True,          # Whether to include the metadata (payload)
    )
    
    # Parse the results (optional: can format it in any way you'd like)
    retrieved_data = []
    for result in results:
        retrieved_data.append({
            'id': result.id,
            'score': result.score,
            'payload': result.payload
        })
    
    return retrieved_data
