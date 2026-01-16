from django.urls import path
from .views import *

urlpatterns = [
    path('cv', ResumeListCreateAPIView.as_view()),
    path('cv/<int:pk>', ResumeRetrieveUpdateAPIView.as_view())
]