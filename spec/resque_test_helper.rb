module ResqueTestHelper
  def enqueue_job
    Resque.enqueue(described_class, *args)
  end

  def queue_size
    Resque.size(queue_name)
  end

  def worker
    Resque::Worker.new(queue_name)
  end

  def execute_job
    worker.reserve
  end
end
