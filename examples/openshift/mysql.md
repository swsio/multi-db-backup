# Deployment example for MySQL, MariaDB and compatible
## Steps to create a MySQL standard Backup Container
- Create PVC for caching large backups prior to S3 upload, this is only necessary if your backup exceeds the emptyDir quota size (for example look at mysql-S3-pvc.yaml) it has to be large enought to hold a complete dump of your DB backup
- Deploy DB backup Container from Image (for example look at mysql-S3-dc.yaml) if you don't want to use a PVC for tmp directory you have to adjust the volumes section to emptyDir like "multi-db-backup" volume that is not used if you use S3

## IMPORTANT
- You have to adjust the ENVs in the DC to fit your environment and S3 credentials!!!
- You have to adjust the PVC size to fit your needs!!!