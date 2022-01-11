FROM python:latest
RUN mkdir /moselhy 
ADD . /moselhy
WORKDIR /moselhy
RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt
EXPOSE 8000
CMD [ "python3", "hello.py" ]
