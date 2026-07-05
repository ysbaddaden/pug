require "wait_group"

struct Pug::Concurrently(T)
  def self.each(sequence : Enumerable(T), &block : T ->)
    new(sequence).each(&block)
  end

  def initialize(@sequence : Enumerable(T))
  end

  def each(workers = 4, &block : T ->) : Nil
    count = @sequence.size.clamp(0..workers)
    channel = Channel(Package).new(count * 4)

    WaitGroup.wait do |wg|
      # start *count* workers
      count.times do
        wg.spawn do
          while pkg = channel.receive?
            block.call(pkg)
          end
        end
      end

      # pass the sequence through the channel, then close for the workers to
      # terminate
      @sequence.each { |pkg| channel.send pkg }
      channel.close
    end
  end
end
