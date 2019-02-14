require 'spec_helper'

RSpec.describe GerritSeed::Shell do
  def capture_output
    stdout, stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new

    result = yield

    OpenStruct.new(
      stdout: $stdout.string,
      stderr: $stderr.string,
      result: result
    )
  ensure
    $stdout, $stderr = stdout, stderr
  end

  it 'forwards stdout' do
    output = capture_output do
      subject.('echo hi')
    end

    expect(output.stdout).to eq("hi\n")
  end

  it 'forwards stderr' do
    output = capture_output do
      subject.('echo hi 1>&2')
    end

    expect(output.stdout).to eq("hi\n")
  end

  it 'returns output' do
    capture_output do
      expect(subject.('echo hi && echo there 1>&2')).to eq("hi\nthere\n")
    end
  end

  it 'raises CommandError on exit code > 0' do
    expect {
      capture_output { subject.('which foo') }
    }.to raise_error(GerritSeed::Shell::CommandError)
  end

  it 'accepts stdin' do
    output = capture_output do
      subject.('cat', stdin: 'gerrit-seed.gemspec')
    end
  end
end
