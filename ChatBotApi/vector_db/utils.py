from dotenv import load_dotenv
import os
from qdrant_client import QdrantClient
from qdrant_client.models import PointStruct
import uuid

load_dotenv('./config.env')

VECTOR_DB_KEY = os.getenv("VECTOR_DB_KEY")

client = QdrantClient(host="localhost", port=6333,api_key=VECTOR_DB_KEY)

def create_collection_if_not_exists(collection_name, vector_size=128, distance="Cosine"):
    collections = client.get_collections()
    existing_collections = [collection.name for collection in collections.collections]
    print(collections)
    if collection_name not in existing_collections:
        client.create_collection(
            collection_name=collection_name,
            vector_size=vector_size,
            distance=distance
        )

def insert_data(collection_name, vector, metadata=None):
    # Ensure the collection exists (or create it)
    create_collection_if_not_exists(collection_name,vector_size=len(vector))
    # Create the PointStruct object for Qdrant
    point = PointStruct(
        id=uuid.uuid5(),
        vector=vector,
        payload=metadata  # Optional metadata
    )

    # Insert the point into the Qdrant collection
    client.upsert(collection_name=collection_name, points=[point])