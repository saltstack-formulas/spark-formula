

control 'spark-baseline' do
  impact 1.0


  describe file('/etc/profile.d/spark.sh') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
  end

  
  describe file('/tmp/spark-2.2.0-bin-hadoop2.7.tgz') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
  end

  
  describe file('/opt/spark-2.2.0-bin-hadoop2.7') do
    it { should be_directory }
    it { should be_owned_by "spark"}
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
  end

  describe file('/opt/spark') do
    it { should be_directory }
    it { should be_symlink } 
    it { should be_owned_by 'spark'}
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
  end


  describe file('/opt/spark/bin/pyspark') do
    it { should be_file }
    it { should be_owned_by 'spark' }
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
    it { should be_executable }
  end

end

control 'spark-defaults' do
  title 'Checking Spark configuration files'
  describe file('/opt/spark/conf/spark-env.sh') do
    it { should be_file }
    it { should be_owned_by 'spark' }
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
    it { should be_writable.by('owner') }
    it { should_not be_writable.by('group') }
    it { should_not be_writable.by('other') }  end
  
  describe file('/opt/spark/conf/log4j.properties') do
    it { should be_file }
    it { should be_owned_by 'spark'}
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
    it { should be_writable.by('owner') }
    it { should_not be_writable.by('group') }
    it { should_not be_writable.by('other') }  end
  
  describe file('/opt/spark/conf/spark-defaults.conf') do
    it { should be_file }
    it { should be_owned_by 'spark' }
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
    it { should be_writable.by('owner') }
    it { should_not be_writable.by('group') }
    it { should_not be_writable.by('other') }    
    its('content') { should match /spark\.local\.dir\s+\/tmp\/not-so-awesome/ }
    its('content') { should match /spark\.executor\.extraClassPath\s+\/opt\/spark\/jars:\/usr\/local/ }
    its('content') { should match /spark\.driver\.memory\s+1g/ }
  end

  describe file('/opt/spark/conf/spark-env.sh') do
    it { should be_file }
    it { should be_owned_by 'spark' }
    it { should be_grouped_into 'spark'}
    it { should be_readable.by('owner') }
    it { should be_readable.by('group') }
    it { should be_readable.by('other') }
    it { should be_writable.by('owner') }
    it { should_not be_writable.by('group') }
    it { should_not be_writable.by('other') }
  end


end
