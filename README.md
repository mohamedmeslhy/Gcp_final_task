## Python_APP_Deployment

Steps to deploy this app 


## Decorization

Use the this version of tornado in ```requirements file``` to install correct image of python.
```bash
tornado== 6.0
```

```bash
FROM python:latest
RUN mkdir /moselhy 
ADD . /moselhy
WORKDIR /moselhy
RUN python -m pip install --upgrade pip
RUN pip install -r requirements.txt
EXPOSE 8000
CMD [ "python3", "hello.py" ]
```
## Bull Redis image for DB
you need to pull image from docker hub .

## push redis image DB & Docker image
push images to ```GCR``` to can make your deployment.

## Build infrastructure using terraform
1- Create vpc & two subnets : one private & one public .

2- create VM private , Nat gateway , router , private cluster in public subnet

3- create GKE private in private subnet 

## Deployments
 
1-  ssh into the private vm then connect to .

2- access your GKE from your VM

3- create Redis deployment & expose its service 
 
4- create deploy python application & expose app with a public HTTP load balancer service

5- access application with loadblancer public ip.
