# DVC live demo

This live demo builds upon the contents of the DVC walkthrough blog article (available in the master branch of this repository, or <a target="_blank" href="https://blog.codecentric.de/en/2019/03/walkthrough-dvc/">here</a>).

*Note:* Please beware that the configuration is tuned for my accounts (GitHub and AWS).
To be fully usable this configuration must be adjusted.

*Note 2:* Beware that the code--whether for Docker, or scripts, or other parts--is far from being clean.

## Quick overview

- The folder `config` contains all configuration (except sensible information for my GitHub and AWS accounts).
- The script `scripts/livedemo_reset_all.sh` initializes the demo GitHub repository and S3 bucket.
- The `Dockerfile` defines a Docker image for each of the three demo [team members](images/team.jpg).
- The script `run_as_user.sh` builds the image and 'logs in' to the container for the username given as the first argument.
  - The optional second parameter `--reset` destroys the current container, before proceeding as described.
- The script `scripts/livedemo.sh` contains the plot of the demo.


