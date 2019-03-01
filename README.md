This post is on how to improve Machine Learning (ML) model development. A model improves when, e.g., you tune it or when more training data becomes available. To measure improvement, you should track at least which data was used for training, the model's current definition, model configuration (hyper parameters), and the achieved model performance. In particular, you should *version* these properties together. [DVC](https://dvc.org/) (data version control) supports you with this task, and more.

# A toy project
This post walks you through an example project (available on GitHub <strong>*ADD LINK*</strong>), in which a neural network is trained to classify images of handwritten digits from the [MNIST data set](http://yann.lecun.com/exdb/mnist/). As the image set of handwritten digits grows, we retrain the model to improve its accuracy.

Implementing a DVC-pipeline makes all of preprocessing, training, performance evaluation, etc. fully reproducible (and therefore also allows to automate retraining). Training data, model configuration, the readily trained model, and performance metrics are versioned such that you can conveniently skip back to any given version. Metrics can be inspected for all versions at the same time, giving an overview over which version performs best. Training data, model, performance metrics, etc. are shared with team members to allow for efficient collaboration.

To prepare the tutorial environment, clone the above git repository, change into the cloned directory, and run the `start_environment.sh` script with parameter `bash`. After the docker image and container are created, you will be logged in to the container as user `dvc` in the tutorial folder `/dvc-walkthrough`. Commands found throughout this post are contained in the script `code/build_tutorial.sh`.

```bash
# % is the host prompt in the cloned folder
# %% is the container prompt in the tutorial folder`

% git clone https://.../dvc-walkthrough.git
% cd dvc-walkthrough
% ./start_environment.sh bash
%% cat code/build_tutorial.sh
```

(Note: Calling `./start_environment.sh build bash` additionally runs the `code/build_tutorial.sh` script.)
<h1>Prepare the repository</h1>
DVC builds on top of git. All DVC configuration is versioned in the same git repository as your model code. The tutorial folder `/dvc-walkthrough` already contains the subfolder `code` holding the required code. Let us turn `/dvc-walkthrough` into a "DVC enabled" git repository.

```bash
# For brevity, code is shortened.
# See code/build_tutorial.sh for complete code.`

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

Stages of a DVC pipeline are connected by *dependencies* and *outputs*. Dependencies and outputs are simply files. E.g. our preprocessing stages depend on the above configuration JSON-files. Our preprocessing stage outputs training image data. If upon execution of a given stage an output of that stage changes, then a stage depending on that output needs to be executed to pick up those changes. E.g. our training stage depends on the training data generated in the preprocessing stage.

The following command configures our preprocessing stage, where the stage's definition is stored in the file given by the `-f` parameter, dependencies are provided using the `-d` parameter, and training image data is output into the folder `data` (`-o` parameter). DVC immediately executes the stage, already generating the desired training data.

```bash
%% dvc run -f preprocess.dvc -d config/preprocess.json -o data python code/preprocess.py
Running command:
        python code/preprocess.py python code/preprocess.py
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

As we see, dvc tracks changes to outputs using their md5-sums. Typically, outputs are large binary files, e.g. image data as in our case. Observe that DVC has added the `data` folder to git's ignore list. This is because large binary files are not to be versioned in git repositories. Instead, DVC manages such files in the folder `.dvc/cache`, which is also ignored by git. To access outputs, DVC implements outputs as hard links into said cache folder.

After adding `.gitignore` and `preprocess.dvc` to version control, we define the other two stages of our pipeline analogously. Note the dependency of our training stage to the training config file. Since training typically takes long times (not so in our toy project, though), we output the readily trained model into a file, namely `model/model.h5`. As DVC versions this binary file, we have easy access to this version of our model in the future.

```bash
%% dvc run -f train.dvc -d data -d config/train.json -o model/model.h5 python code/train.py
%% dvc run -f evaluate.dvc -d model/model.h5 -M model/metrics.json python code/evaluate.py
```

Observe the definition of the file `model/metrics.json` as a *metric* (`-M` parameter). Metrics can be inspected using DVC, as we discuss below. To wrap up our first version of the pipeline, we put all stage definitions (`.dvc`-files) under version control and add a tag.

```bash
%% git add ...
%% git commit ...
%% git tag -a 0.1 -m "initial pipeline version 0.1"
```

Finally, let's have a look at how DVC renders our current pipeline.

```bash
%% dvc pipeline show --ascii evaluate.dvc`
```
![pipeline rendered by dvc](https://blog.codecentric.de/files/2019/03/pipeline2.jpg)

# DVC-cached files
Let us skip back to the version when no pipeline was defined, yet. Recall that DVC uses git to keep track of which output data belongs to the checked out version. Therefore, we have to additionally tell DVC to synchronize outputs using the command `dvc checkout`.

```bash
%% git checkout 0.0
%% dvc checkout
%% ls data
ls: cannot access 'data': No such file or directory
```

Back to the present, we find that DVC has restored all training data.

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

When changing the amount of training data, the entire pipeline can be reproduced by calling the `dvc repro`-command with the parameter `evaluate.dvc`, which defines the last stage of the pipeline.

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

Let us save this version of our pipeline.

```bash
%% git add preprocess.dvc train.dvc evaluate.dvc config/preprocess.json model/metrics.json
%% git commit -m "0.2 more training data"
%% git tag -a 0.2 -m "0.2 more training data"
```

# Reproduce partially
What if only the training definition changes, but training data remains the same? Our expectation should be that all but the preprocessing state are reproduced. We even have control over which parts of the pipeline are reproduced. In a first step, we reproduce only the training stage by calling the `dvc repro` command with parameter `train.dvc`, the stage in the middle of the pipeline.

```bash
%% echo '{ "num_conv_filters" : 64 }' &gt; config/train.json
%% dvc repro train.dvc
...
Stage 'preprocess.dvc' didnt change.
Warning: Dependency 'config/train.json' of 'train.dvc' changed.
Stage 'train.dvc' changed.
Reproducing 'train.dvc'...
```

We can now reproduce the entire pipeline, where only evaluation really needs to be executed, since re-training was already performed in the previous step.

```bash
%% dvc repro evaluate.dvc
...
Stage 'preprocess.dvc' didnt change.
Stage 'train.dvc' didnt change.
Warning: Dependency 'model/model.h5' of 'evaluate.dvc' changed.
Stage 'evaluate.dvc' changed.
Reproducing 'evaluate.dvc'...
```

Finally, let us also increase the amount of available training data and trigger the entire pipeline by reproducing the `evaluate.dvc` stage.

```bash
%% echo '{ "train_data_size" : 0.3 }' &gt; config/preprocess.json
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

Of course, we save this version of our pipeline.

```bash
%% git add config/preprocess.json config/train.json evaluate.dvc preprocess.dvc train.dvc model/metrics.json
%% git commit -m "0.3 more training data, more convolutions"
%% git tag -a 0.3 -m "0.3 more training data, more convolutions"
```

# Compare versions
Recall that we have defined a <i>metric</i> for the evaluation stage. DVC can list metrics files for branches or tags in an entire git repository, which allows us to compare model performances for various versions of our pipeline.

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

We store metrics in JSON-files. To display only the metric of interest, DVC allows to configure an XPath expression, which is stored in the configuration of the corresponding stage. CSV-files are supported as well.

```bash
%% dvc metrics modify model/metrics.json --type json --xpath acc
%% cat evaluate.dvc
...
metric:
_type: json
_xpath: acc
...
```

(Note that DVC does not interpret metrics, and instead treats them as plain text. Also, note that for consistent metric display over all versions, metrics should be defined in the very beginning of your project: E.g. XPath expressions are stored within the stage's `.dvc`-file and should be the same for each version.)

# Share data
When developing models in teams, sharing training data, readily trained models, and performance metrics is crucial for efficient collaboration--each team member retraining the same model is a waste of time. Recall that such binary data is not stored in our git repository. Instead, DVC manages these files in its `.dvc/cache` folder. DVC allows to push cached file to remote storage (SSH, NAS, Amazon, S3, ...). From there, each team member can pull data to their individual workspace's DVC cache and work with that data as usual.

For the purpose of this walkthrough, we fake a remote using the local folder `/remote`. Let us demonstrate how to push cached data to the remote.

```bash
%% mkdir /remote/cache
%% dvc remote add -d fake_remote /remote/cache
%% git add .dvc/config
%% git commit -m "configure remote"
%% dvc push -T
```

The `-T` parameter pushes cached files for all tags. Note that `dvc push` intelligently pushes only new or changed data, and skips over data that has remained the same since the last push.

How would your team member access your pushed training data and readily trained models? (If you followed along in your shell, leave the container and recreate the container by again calling `./start_environment.sh bash`. The following steps are documented in `code/clone_tutorial.sh` and should be applied in the `/tmp`-folder.) Cloning the git repository will *not* checkout training data, etc. since these files are managed in DVC's remote storage. We need to instruct DVC to pull it in. Thereafter, we can use it as before.

```bash
%% git clone /remote/git-repo cloned
%% cd cloned
%% ls data
ls: cannot access 'data': No such file or directory # no training data there :(
%% dvc pull -T
%% ls data
0  1  2  3  4  5  6  7  8  9 # theeere is our training data :)
```

# Remarks
Observe that stage definitions call arbitrary commands, i.e. DVC is language-agnostic and not bound to Python. No one can stop you from implementing stages in Bash, C, or whatever.

DVC does not only support tags for organizing versions of your pipeline, it also allows to utilize branch structures.

Pushing/pulling DVC-cached data for all tags (`-T` parameter) is not advisable in general, since you will send/receive *lots* of data.
