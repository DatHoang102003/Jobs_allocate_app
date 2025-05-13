let jobs = [];

exports.getAllJobs = (req, res) => {
  res.json(jobs);
};

exports.getJobById = (req, res) => {
  const job = jobs.find(j => j.id === req.params.id);
  if (!job) return res.status(404).json({ message: 'Job not found' });
  res.json(job);
};

exports.createJob = (req, res) => {
  const newJob = {
    id: Date.now().toString(),
    title: req.body.title,
    assignedTo: req.body.assignedTo
  };
  jobs.push(newJob);
  res.status(201).json(newJob);
};
