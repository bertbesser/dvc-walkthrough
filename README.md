This post is on how to systematially organize Machine Learning (ML) model development. A model's performance improves when, e.g., you tune its parameters or when more training data becomes available. To measure improvement, you should track at least which data was used for training, the model's current definition, model configuration (hyper parameters, etc.), and the achieved model performance. In particular, you should *version* these properties *together*.

[DVC](https://dvc.org/) (data version control) supports you with this task, and more.

Implementing a DVC-*pipeline* makes all of preprocessing, training, performance evaluation, etc. fully reproducible (and therefore also allows to automate retraining). Training data, model configuration, the readily trained model, and performance metrics are versioned such that you can conveniently skip back to any given version and inspect all associated configuration and data. Also, DVC provides an overview of metrics for all versions of your pipeline, which helps with identifying your best work. Training data, trained models, performance metrics, etc. are shared with team members to allow for efficient collaboration.

# A toy project
This post walks you through an example project (available on GitHub <strong>*ADD_LINK*</strong>), in which a neural network is trained to classify images of handwritten digits from the [MNIST data set](http://yann.lecun.com/exdb/mnist/). As the available image set of handwritten digits grows, we retrain the model to improve its accuracy.

To prepare the tutorial environment, clone the above Git repository, change into the cloned directory, and run the `start_environment.sh` script with parameter `bash`. After the docker image and container are created, you will be logged in to the container as user `dvc` in the tutorial folder `/dvc-walkthrough`. Commands given throughout this post are contained in the script `code/build_tutorial.sh`.

```bash
# % is the host prompt in the cloned folder
# %% is the container prompt in the tutorial folder /dvc-walkthrough

% git clone https://ADD_LINK/dvc-walkthrough.git
% cd dvc-walkthrough
% ./start_environment.sh bash
%% cat code/build_tutorial.sh
```

(Note: Calling `./start_environment.sh build bash` additionally runs the `code/build_tutorial.sh` script.)

# Prepare the repository
DVC is built on top of Git. All DVC configuration is versioned in the same Git repository as your model code, in the subfolder `.dvc`, among others. The tutorial folder `/dvc-walkthrough` already contains the subfolder `code` holding the required code. Let us turn `/dvc-walkthrough` into a "DVC-enabled" Git repository. Note that tagging this freshly initialized repository is not a must&mdash;we create a tag only for the purpose of later parts of this walkthrough.

```bash
# Code is shortened, for brevity.
# See code/build_tutorial.sh for complete code.

%% git init
%% git add code
%% git commit -m "initial import"
%% dvc init
%% git status
        new file: .dvc/.gitignore
        new file: .dvc/config
%% git add .dvc
%% git commit -m "init dvc"
%% git tag -a 0.0 -m "freshly initialized with no pipeline defined, yet"
```

# Define the pipeline
Our pipeline consists of three stages, namely
1. preprocessing,
2. training, and
3. evalutation,

where we input raw data and output performance metrics of the trained model. Here is a schematic:
![pipeline](https://blog.codecentric.de/files/2019/03/pipeline.jpg)

We implement a dummy preprocessing stage, which simply copies given training data into the repository. However, since our goal is to retrain the model as more and more training data is available, our preprocessing stage can be configured for the amount of data to be copied. This configuration is located in the file `config/preprocess.json`. Similarly, training stage configuration is located in `config/train.json`. Let's put this congiuration under version control.

```bash
%% mkdir config
%% echo '{ "train_data_size" : 0.1 }' > config/preprocess.json
%% echo '{ "num_conv_filters" : 32 }' > config/train.json
%% git add config/preprocess.json config/train.json
%% git commit -m "add config"
```

Stages of a DVC pipeline are connected by *dependencies* and *outputs*. Dependencies and outputs are simply files. E.g. our preprocessing stage *depends* on the above configuration file `config/preprocess.json`. The preprocessing stage *outputs* training image data. If upon execution of a given stage an output of that stage changes, then another stage depending on that output needs to be executed to pick up those changes. E.g. our training stage depends on the training data generated in the preprocessing stage.

The following command configures our preprocessing stage, where the stage's definition is stored in the file given by the `-f` parameter, dependencies are provided using the `-d` parameter, and training image data is output into the folder `data` (`-o` parameter). DVC immediately executes the stage, already generating the desired training data.

```bash
%% dvc run -f preprocess.dvc -d config/preprocess.json -o data python code/preprocess.py
Running command:
        python code/preprocess.py
Computing md5 for a large directory data/2. This is only done once.
...
%% git status
        .gitignore
        preprocess.dvc
%% cat .gitignore
data
%% git add .gitignore preprocess.dvc
git commit -m "init preprocess stage"
```

Recall that our preprocessing stage outputs image data into the folder `data`. DVC has added the `data` folder to Git's ignore list. This is because large binary files are not to be versioned in Git repositories. Instead, DVC manages such large files in the folder `.dvc/cache`, which is also ignored by Git (as configured in `.dvc/.gitignore`). DVC-cached files are exposed to us as hardlinks from output files into DVC's cache folder.

After adding `.gitignore` and `preprocess.dvc` to version control, we define the other two stages of our pipeline analogously, see the following code block. Note the dependency of our training stage to the training config file. Since training typically takes long times (not so in our toy project, though), we output the readily trained model into a file, namely `model/model.h5`. As DVC versions this binary file, we have easy access to this version of our model in the future.

```bash
%% dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python code/train.py
...
%% dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python code/evaluate.py
...
```

For the evaluation stage, observe the definition of the file `model/metrics.json` as a *metric* (`-M` parameter). Metrics can be inspected using the `dvc metrics` command, as we discuss below. To wrap up our first version of the pipeline, we put all stage definitions (`.dvc`-files) under version control and add a tag.

```bash
%% git add ...
%% git commit ...
%% git tag -a 0.1 -m "initial pipeline version 0.1"
```

*Remark*: DVC does not only support tags for organizing versions of your pipeline, it also allows to utilize branch structures.

Finally, let's have a brief look at how DVC renders our pipeline.

```bash
%% dvc pipeline show --ascii evaluate.dvc
```
![pipeline rendered by dvc](https://blog.codecentric.de/files/2019/03/pipeline-dvc.jpg)

*Remark*: Observe that stage definitions call arbitrary commands, i.e., DVC is language-agnostic and not bound to Python. No one can stop you from implementing stages in Bash, C, or any other of your favorite languages.

# DVC-cached files
Let us skip back to our initial repository version. Since no pipeline is defined, yet, none of our training data, model, or metrics exist.  Recall that DVC uses Git to keep track of which output data belongs to the checked out version. Therefore, we have to instruct DVC to synchronize outputs using the command `dvc checkout`.

```bash
%% git checkout 0.0
%% dvc checkout
%% ls data
ls: cannot access 'data': No such file or directory # desired :-)
```

Back to the latest version, we find that DVC has restored all training data.

```bash
%% git checkout 0.1
%% dvc checkout
%% ls data
0  1  2  3  4  5  6  7  8  9 # one folder of images for each digit
```

# Reproduce the pipeline
Pat yourself on the back. You have mastered *building* a pipeline, which is the hard part. *Reproducing* (parts of) it is easy af. First, note that if we do not change any dependencies, there is nothing to be reproduced.

```bash
%% dvc repro evaluate.dvc
...
Stage 'preprocess.dvc' didnt change.
Stage 'train.dvc' didnt change.
Stage 'evaluate.dvc' didnt change.
Pipeline is up to date. Nothing to reproduce.
```

When changing the amount of training data, the entire pipeline can be reproduced by calling the `dvc repro`-command with parameter `evaluate.dvc`, which defines the final stage of the pipeline.

```bash
%% echo '{ "train_data_size" : 0.2 }' > config/preprocess.json
%% dvc repro evaluate.dvc
...
Warning: Dependency 'config/preprocess.json' of 'preprocess.dvc' changed.
Stage 'preprocess.dvc' changed.
Reproducing 'preprocess.dvc'
...
Warning: Dependency 'data' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'
...
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'
```

Observe that DVC tracks changes to dependencies and outputs through md5-sums stored in their corresponding stage's `.dvc`-file:

```bash
%% git status
        modified:   config/preprocess.json
        modified:   evaluate.dvc
        modified:   model/metrics.json
        modified:   preprocess.dvc
        modified:   train.dvc
%% git diff preprocess.dvc
...
deps:
-- md5: 44260f0cf26e82df91b23ab9a75bf4ae
+- md5: 2e13ea50a381a9be4809026b71210d5a
...
outs:
-  md5: b5136af809e828b0c51735f40c5d6db6.dir
+  md5: 8265c35e6eb17e79de9705cbbbd9a515.dir
```

Let us save this version of our pipeline and tag it.

```bash
%% git add preprocess.dvc train.dvc evaluate.dvc config/preprocess.json model/metrics.json
%% git commit -m "0.2 more training data"
%% git tag -a 0.2 -m "0.2 more training data"
```

# Reproduce partially
What if only training *configuration* changes, but training *data* remains the same? All stages but the preprocessing stage should be reproduced. We have control over which stages of the pipeline are reproduced. In a first step, we reproduce only the training stage by issuing the `dvc repro` command with parameter `train.dvc`, the stage in the middle of the pipeline.

```bash
%% echo '{ "num_conv_filters" : 64 }' > config/train.json
%% dvc repro train.dvc
...
Stage 'preprocess.dvc' didnt change.
Warning: Dependency 'config/train.json' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'...
```

We can now reproduce the entire pipeline. Since we already performed re-training, only the evaluation stage will be executed.

```bash
%% dvc repro evaluate.dvc
...
Stage 'preprocess.dvc' didnt change.
Stage 'train.dvc' didnt change.
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'...
```

Finally, let us increase the amount of available training data and trigger the entire pipeline by reproducing the `evaluate.dvc` stage.

```bash
%% echo '{ "train_data_size" : 0.3 }' > config/preprocess.json
%% dvc repro evaluate.dvc
...
Warning: Dependency 'config/preprocess.json' of 'preprocess.dvc' changed.
Stage 'preprocess.dvc' changed.
Reproducing 'preprocess.dvc'
...
Warning: Dependency 'data' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'
...
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'...
```

Again, we save this version of our pipeline and tag it.

```bash
%% git add config/preprocess.json config/train.json evaluate.dvc preprocess.dvc train.dvc model/metrics.json
%% git commit -m "0.3 more training data, more convolutions"
%% git tag -a 0.3 -m "0.3 more training data, more convolutions"
```

# Compare versions
Recall that we have defined a *metric* for the evaluation stage, in the file `model/metrics.json`. DVC can list metrics files for all tags in the entire Git repository, which allows us to compare model performances for various all versions of our pipeline. Clearly, increasing the amount of training data and adding convolution filters to the neural network improves the model's accuracy.

```bash
%% dvc metrics show -T # -T for all tags
master:
        model/metrics.json: [0.9565656557227626]
0.1:
        model/metrics.json: [0.896969696969697]
0.2:
        model/metrics.json: [0.9196969693357294]
0.3:
        model/metrics.json: [0.9565656557227626]
```

Actually, the file `model/metrics.json` stores not only the model's accuracy, but also its loss. To display only the accuracy, we have configured DVC with an XPath expression as follows. This expression is stored in the corresponding stage's `.dvc` file.

```bash
%% dvc metrics modify model/metrics.json --type json --xpath acc
%% cat evaluate.dvc
...
metric:
 type: json
 xpath: acc
...
```

*Remark 1*: DVC also supports metrics stored in CSV files or plain text files. In particular, DVC does not interpret metrics, and instead treats them as plain text.

*Remark 2*: For consistent metrics display over all pipeline versions, metrics should be configured in the very beginning of your project. In this case, configuration contained in `.dvc`-files is the same for all versions.

# Share data
When developing models in teams, sharing training data, readily trained models, and performance metrics is crucial for efficient collaboration--each team member retraining the same model is a waste of time. Recall that stage output data is not stored in the Git repository. Instead, DVC manages these files in its `.dvc/cache` folder. DVC allows to push cached files to remote storage (SSH, NAS, Amazon, S3, ...). From there, each team member can pull that data to their individual workspace's DVC cache and work with it as usual.

For the purpose of this walkthrough, we fake remote storage using a local folder called `/remote`. Here is how to configure the remote and push data to it.

```bash
%% mkdir /remote/cache
%% dvc remote add -d fake_remote /remote/cache # -d for making the remote default
%% git add .dvc/config # save the remote's configuration
%% git commit -m "configure remote"
%% dvc push -T
```

The `-T` parameter pushes cached files for all tags. Note that `dvc push` intelligently pushes only new or changed data, and skips over data that has remained the same since the last push.

How would your team member access your pushed data? (If you followed along in your shell, exit the container and recreate it by calling `./start_environment.sh bash`. The following steps are documented in `code/clone_tutorial.sh` and should be applied in the `/tmp`-folder.) Recall that cloning the Git repository will *not* checkout training data, etc. since such files are managed in by DVC. We need to instruct DVC to pull that data from the remote storage. Thereafter, we can access the data as before.

```bash
%% git clone /remote/git-repo cloned
%% cd cloned
%% ls data
ls: cannot access 'data': No such file or directory # no training data there :(
%% dvc pull -T # -T to pull for all tags
%% ls data
0  1  2  3  4  5  6  7  8  9 # theeere is our training data :)
```

*Remark*: Pushing/pulling DVC-managed data for all tags (`-T` parameter) is not advisable in general, since you will send/receive *lots* of data.

# Conclusion
DVC allows you to define reproducible ML pipelines and version pipelines *together with* their associated training data, configuration, performance metrics, etc. Performance metrics can be evaluated for all versions of a pipeline. Training data, trained models, and other associated binary data can be shared with team members for efficient collaboration.
