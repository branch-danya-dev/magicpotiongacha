"""Offline intake checks using synthetic archives, never model/provider requests."""
import io,stat,unittest,zipfile
from stage_source import source,members
class Intake(unittest.TestCase):
    def check_zip(self,entries):
        content=io.BytesIO()
        with zipfile.ZipFile(content,'w') as archive:
            for name in entries:archive.writestr(name,b'fixture')
        content.seek(0)
        with zipfile.ZipFile(content) as archive:return list(members(archive))
    def test_noai_before_file_access(self):
        with self.assertRaisesRegex(PermissionError,'NOAI'):source('oak_maple')
    def test_first_pair_and_dungdao_licenses(self):
        for key in ('magic_igor','stylized_stefan','curved_dungdao'):self.assertEqual(source(key)['license']['slug'],'by')
    def test_path_escape(self):
        for name in ('../escape.fbx','C:/escape.fbx','folder\\..\\escape.fbx','/escape.png','a.png:payload'):
            with self.subTest(name=name),self.assertRaises(ValueError):self.check_zip([name])
    def test_case_collision(self):
        with self.assertRaises(ValueError):self.check_zip(['Tree.fbx','tree.fbx'])
    def test_code_not_extracted(self):
        with self.assertRaises(ValueError):self.check_zip(['source/model.py'])
    def test_symlink(self):
        link=zipfile.ZipInfo('linked.fbx');link.external_attr=(stat.S_IFLNK|0o777)<<16
        with self.assertRaises(ValueError):self.check_zip([link])
    def test_reviewed_data(self):
        self.assertEqual(len(self.check_zip(['source/tree.fbx','textures/tree.png','license.txt'])),3)
if __name__=='__main__':unittest.main()
