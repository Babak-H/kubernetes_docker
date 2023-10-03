FROM python:3.11.06a-alpine.15
WORKDIR /code
COPY requirements.txt /code

# install flask and redis connector package for python
RUN pip install -r requirements.txt --no-cache-dir
COPY . /code
CMD python app.py

