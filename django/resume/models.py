from django.db import models

class ResumeStatus(models.TextChoices):
    NEW = "new", "Новый"
    INTERVIEW = "interview", "Назначено собеседование"
    APPROVED = "approved", "Принят"
    REJECTED = "rejected", "Отказ"

class EducationLevel(models.TextChoices):
    SECONDARY = 'secondary', 'Среднее'
    SPECIAL = 'special', 'Среднее специальное'
    HIGHER = 'higher', 'Высшее'
    UNHIGHER = 'unhigher', 'Высшее неоконченное'
    
class Resume(models.Model):
    fio = models.CharField(max_length=255, verbose_name='ФИО')
    email = models.EmailField(verbose_name='Email')
    city = models.CharField(max_length=255, verbose_name='Город')
    phone = models.CharField(max_length=11, verbose_name='Телефон')
    birth_date = models.DateField(verbose_name='Дата рождения')
    photo_link = models.URLField(verbose_name='Ссылка на фото', null=True, blank=True)
    profession = models.CharField(max_length=255, verbose_name='Профессия')
    salary = models.DecimalField(max_digits=15, decimal_places=0, verbose_name='Зарплата')
    skills = models.TextField(verbose_name='Навыки')
    about = models.TextField(verbose_name='О себе')
    status = models.CharField(max_length=32, choices=ResumeStatus.choices, default=ResumeStatus.NEW, verbose_name='Статус')

    level = models.CharField(max_length=20, choices=EducationLevel.choices)
    institution = models.CharField(max_length=255, null=True, blank=True)
    faculty = models.CharField(max_length=255, null=True, blank=True)
    specialization = models.CharField(max_length=255, null=True, blank=True)
    grad_year = models.PositiveSmallIntegerField(null=True, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True, verbose_name="Создано")
    updated_at = models.DateTimeField(auto_now=True, verbose_name="Обновлено")
